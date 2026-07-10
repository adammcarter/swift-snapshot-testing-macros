import Foundation
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@testable import SnapshotMigrationSupport

@Suite
struct ApplySafetyTests {
  @Test
  func applyLockIsExclusive() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let first = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { first.release() }

    do {
      _ = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
      Issue.record("Expected acquire to fail while lock is held")
    } catch let error as ApplyLockError {
      guard case .lockHeld = error else {
        Issue.record("Expected lockHeld, got \(error)")
        return
      }
    } catch {
      Issue.record("Expected ApplyLockError, got \(error)")
    }
  }

  @Test
  func staleLockIsReclaimedWhenTimeoutIsZero() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let lockPath = URL(fileURLWithPath: fixture.root).appendingPathComponent(".snapshot-migration.lock").path
    let stalePID = findUnusedPID()
    try "\(stalePID)".write(toFile: lockPath, atomically: true, encoding: .utf8)

    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    lock.release()
  }

  @Test
  func releaseDoesNotRemoveReplacementLockFile() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let lockPath = URL(fileURLWithPath: fixture.root).appendingPathComponent(".snapshot-migration.lock").path
    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)

    // Simulate another process replacing the lock file behind this lock object.
    _ = unlink(lockPath)
    try "replacement-owner".write(toFile: lockPath, atomically: true, encoding: .utf8)

    lock.release()

    #expect(FileManager.default.fileExists(atPath: lockPath))
    let contents = try String(contentsOfFile: lockPath, encoding: .utf8)
    #expect(contents == "replacement-owner")
  }

  @Test
  func doubleReleaseIsANoOpAndPreservesSubsequentLock() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let lockPath = URL(fileURLWithPath: fixture.root).appendingPathComponent(".snapshot-migration.lock").path

    let first = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    first.release()

    let second = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { second.release() }

    // A second release of the already-released lock must not disturb the new holder.
    first.release()

    #expect(FileManager.default.fileExists(atPath: lockPath))
    do {
      _ = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
      Issue.record("Expected acquire to fail while second lock is held")
    } catch let error as ApplyLockError {
      guard case .lockHeld = error else {
        Issue.record("Expected lockHeld, got \(error)")
        return
      }
    } catch {
      Issue.record("Expected ApplyLockError, got \(error)")
    }
  }

  @Test
  func preconditionHashMismatchIsRejected() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let path = try fixture.write(path: "Tests/A.swift", contents: "@SnapshotSuite struct A {}")
    let replacer = AtomicFileReplacer()

    do {
      try replacer.replace(path: path, expectedHash: "wrong-hash", newContents: "updated")
      Issue.record("Expected replace to fail for precondition hash mismatch")
    } catch let error as AtomicReplaceError {
      #expect(error == .preconditionFailed)
    } catch {
      Issue.record("Expected AtomicReplaceError, got \(error)")
    }
  }

  @Test
  func symlinkTargetIsRejectedAsUnsafe() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let filePath = try fixture.write(path: "Tests/A.swift", contents: "@SnapshotSuite struct A {}")
    let symlinkPath = URL(fileURLWithPath: fixture.root).appendingPathComponent("Tests/A-link.swift").path
    try FileManager.default.createSymbolicLink(atPath: symlinkPath, withDestinationPath: filePath)

    let replacer = AtomicFileReplacer()
    let expectedHash = SHA256Hasher.hash("@SnapshotSuite struct A {}")

    do {
      try replacer.replace(path: symlinkPath, expectedHash: expectedHash, newContents: "updated")
      Issue.record("Expected replace to reject symlink targets")
    } catch let error as AtomicReplaceError {
      #expect(error == .unsafeNonRegularFile)
    } catch {
      Issue.record("Expected AtomicReplaceError, got \(error)")
    }
  }

  @Test
  func stagingStoreUsesCanonicalTmpRoot() throws {
    let store = try RunStagingStore.create(runID: "apply-safety-\(UUID().uuidString)")
    defer { store.remove() }

    #expect(store.root.hasPrefix("/tmp/snapshot-migration/"))
  }

  @Test
  func stagingParentDirectoryIsPrivateToTheCurrentUser() throws {
    let store = try RunStagingStore.create(runID: "apply-parent-perms-\(UUID().uuidString)")
    defer { store.remove() }

    let attributes = try FileManager.default.attributesOfItem(atPath: "/tmp/snapshot-migration")
    let permissions = (attributes[.posixPermissions] as? NSNumber)?.int16Value
    #expect(permissions == 0o700)
  }

  @Test
  func stagingCapExceededLatchesAcrossSubsequentWrites() throws {
    var store = try RunStagingStore.create(runID: "apply-cap-\(UUID().uuidString)")
    defer { store.remove() }

    do {
      try store.stage(relativePath: "Tests/A.swift", contents: "12345", maxStagedBytes: 4)
      Issue.record("Expected first staging write to exceed cap")
    } catch let error as RunStagingStoreError {
      #expect(error == .tempStorageCapExceeded)
    } catch {
      Issue.record("Expected RunStagingStoreError, got \(error)")
    }

    do {
      try store.stage(relativePath: "Tests/B.swift", contents: "1", maxStagedBytes: 4)
      Issue.record("Expected staging cap to remain latched after first exceed")
    } catch let error as RunStagingStoreError {
      #expect(error == .tempStorageCapExceeded)
    } catch {
      Issue.record("Expected RunStagingStoreError, got \(error)")
    }
  }

  @Test
  func applyModeDoesNotMutateFilesWhenStagingFails() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct SnapshotSuiteExample {
      @SnapshotTest
      func makeView() -> some View {
        Text("hello")
      }
    }
    """

    let targetPath = try fixture.write(path: "Tests/SnapshotSuiteExample.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: true,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 1,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    defer { removeStagingDirectory(of: outcome) }
    let updated = try String(contentsOfFile: targetPath, encoding: .utf8)

    #expect(outcome.exitCode == .migrationFailure)
    #expect(updated == original)
  }

  @Test
  func applyModeSkipsAllAppliesWhenAnyStagingFails() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct SnapshotSuiteExample {
      @SnapshotTest
      func makeView() -> some View {
        Text("hello")
      }
    }
    """

    let firstPath = try fixture.write(path: "Tests/First.swift", contents: original)
    let secondPath = try fixture.write(path: "Tests/Second.swift", contents: original)

    let rewritten = try SnapshotMigrationRewriter().rewrite(source: original)
    #expect(rewritten.changed)
    let maxStagedBytes = rewritten.output.utf8.count + 1

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: true,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: maxStagedBytes,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    defer { removeStagingDirectory(of: outcome) }
    let firstUpdated = try String(contentsOfFile: firstPath, encoding: .utf8)
    let secondUpdated = try String(contentsOfFile: secondPath, encoding: .utf8)

    #expect(outcome.exitCode == .migrationFailure)
    #expect(firstUpdated == original)
    #expect(secondUpdated == original)
  }

  @Test
  func dryRunReturnsSuccessAndLeavesNoTempOutput() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct SnapshotSuiteExample {
      @SnapshotTest
      func makeView() -> some View {
        Text("hello")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Candidate.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 10_000,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    let fileManager = FileManager.default
    defer { try? fileManager.removeItem(atPath: tempRoot) }
    let updated = try String(contentsOfFile: filePath, encoding: .utf8)

    #expect(outcome.exitCode == .success)
    #expect(outcome.report.reportSchemaVersion == 4)
    #expect(outcome.report.timings.total.wallSeconds > 0)
    #expect(outcome.report.timings.rewriteStage.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.wallSeconds == 0)
    #expect(!fileManager.fileExists(atPath: tempRoot))
    #expect(outcome.keptStagingRoot == nil)
    #expect(updated == original)
  }

  @Test
  func stagingIssueCodesDistinguishCapWriteAndSetupFailures() {
    #expect(
      MigrationRunner.stagingIssueCode(for: RunStagingStoreError.tempStorageCapExceeded)
        == "temp-storage-cap-exceeded"
    )
    #expect(
      MigrationRunner.stagingIssueCode(for: RunStagingStoreError.writeFailed("/tmp/x"))
        == "staging-write-failed"
    )
    #expect(
      MigrationRunner.stagingIssueCode(for: RunStagingStoreError.invalidRelativePath("../x"))
        == "staging-invalid-path"
    )
    // Anything thrown while creating the staging directory itself (mkdir/chmod
    // failures surface as Foundation errors) must not masquerade as a cap breach.
    #expect(
      MigrationRunner.stagingIssueCode(for: CocoaError(.fileWriteNoPermission))
        == "staging-setup-failed"
    )
  }

  /// Tests that keep the staging directory (`--keep-temp`, or apply-failure recovery)
  /// must remove it themselves so repeated test runs don't accumulate directories
  /// under /tmp/snapshot-migration.
  private func removeStagingDirectory(of outcome: MigrationRunOutcome) {
    let root = outcome.keptStagingRoot ?? "/tmp/snapshot-migration/\(outcome.report.runID)"
    try? FileManager.default.removeItem(atPath: root)
  }

  private func findUnusedPID(startingAt start: Int32 = 500_000) -> Int32 {
    var candidate = start
    while candidate < Int32.max {
      if kill(candidate, 0) == -1, errno == ESRCH {
        return candidate
      }
      candidate += 1
    }
    return 999_999
  }
}
