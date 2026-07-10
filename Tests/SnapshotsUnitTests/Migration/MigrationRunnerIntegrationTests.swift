import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationRunnerIntegrationTests {
  @Test
  func dryRunProducesReportAndLeavesNoStagingDirectoryBehind() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Default")
      func profile() -> some View {
        Text("A")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Profile.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    let fileManager = FileManager.default
    defer { try? fileManager.removeItem(atPath: tempRoot) }

    let current = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(outcome.exitCode == .success)
    #expect(outcome.report.reportSchemaVersion == 4)
    #expect(outcome.report.timings.total.wallSeconds > 0)
    #expect(outcome.report.timings.total.cpuSeconds >= 0)
    #expect(outcome.report.timings.scan.wallSeconds >= 0)
    #expect(outcome.report.timings.rewriteStage.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.wallSeconds == 0)
    #expect(outcome.report.timings.apply.cpuSeconds == 0)
    #expect(!fileManager.fileExists(atPath: tempRoot))
    #expect(outcome.keptStagingRoot == nil)
    #expect(current == original)
  }

  @Test
  func dryRunWithKeepTempKeepsStagingDirectoryAndReportsKeptPath() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Default")
      func profile() -> some View {
        Text("A")
      }
    }
    """

    try fixture.write(path: "Tests/Profile.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: true,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    let fileManager = FileManager.default
    defer { try? fileManager.removeItem(atPath: tempRoot) }

    let stagedPath = "\(tempRoot)/Tests/Profile.swift"
    #expect(outcome.exitCode == .success)
    #expect(outcome.keptStagingRoot == tempRoot)
    #expect(fileManager.fileExists(atPath: tempRoot))
    #expect(fileManager.fileExists(atPath: stagedPath))
    let staged = try String(contentsOfFile: stagedPath, encoding: .utf8)
    #expect(staged.contains("#expectSnapshot"))
  }

  @Test
  func failedApplyKeepsStagedCopiesForRecovery() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Default")
      func profile() -> some View {
        Text("A")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Profile.swift", contents: original)

    // Hold the apply lock so the apply phase fails without mutating any file.
    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { lock.release() }

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    let fileManager = FileManager.default
    defer { try? fileManager.removeItem(atPath: tempRoot) }

    let current = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(outcome.exitCode == .applySafetyFailure)
    #expect(current == original)
    // Staged rewrites are the recovery copy for a failed apply run: they must survive.
    #expect(outcome.keptStagingRoot == tempRoot)
    #expect(fileManager.fileExists(atPath: "\(tempRoot)/Tests/Profile.swift"))
  }

  @Test
  func applyBlockedByMigrationFailureZeroesStagedDeclarationCountLikeLockFailure() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    // The scanner processes candidates in sorted path order and the staging cap latches once
    // exceeded, so the first (small) file stages cleanly — incrementing `migratedDeclarations` —
    // while the second (large) file's rewritten output blows the cap, its staging throws, and
    // `hadMigrationFailures` is set. The apply phase is then skipped entirely. Staged-but-unwritten
    // work must be accounted like the apply-lock-failure path (moved to failed, not left as
    // `migrated`) so the report never claims work that never reached disk.
    try fixture.write(
      path: "Tests/A_Small.swift",
      contents: """
      @SnapshotTest("Small")
      func small() -> some View {
        Text("A")
      }
      """
    )
    let hugeComment = "// " + String(repeating: "padding ", count: 400)
    try fixture.write(
      path: "Tests/Z_Large.swift",
      contents: """
      \(hugeComment)
      @SnapshotTest("Large")
      func large() -> some View {
        Text("B")
      }
      """
    )

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      // Fits the small file's rewritten output but not the large file's padded output.
      maxStagedBytes: 1_000,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    defer { try? FileManager.default.removeItem(atPath: tempRoot) }

    #expect(outcome.exitCode == .migrationFailure)
    // Nothing was applied, so no declaration may be reported as migrated.
    #expect(outcome.report.filesApplied == 0)
    #expect(outcome.report.migratedDeclarations == 0)
    // The staged-but-unwritten declaration is counted as failed, matching the lock-failure path.
    #expect(outcome.report.failedDeclarations == 2)
    #expect(outcome.report.migrationPercentage == 0)
  }

  @Test
  func applyRunWithAMigrationFailureExitsMigrationFailure() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    // A single migratable file whose rewritten output blows the staging cap: staging throws and
    // `hadMigrationFailures` is set with `failedDeclarations > 0`. Every site that sets
    // `hadMigrationFailures` also increments `failedDeclarations`, so `resolveExitCode` alone
    // must return `.migrationFailure` here — pinning the invariant that `hadMigrationFailures`
    // never coincides with a `.success` exit code.
    let hugeComment = "// " + String(repeating: "padding ", count: 400)
    try fixture.write(
      path: "Tests/Large.swift",
      contents: """
      \(hugeComment)
      @SnapshotTest("Large")
      func large() -> some View {
        Text("B")
      }
      """
    )

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 1_000,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    defer { try? FileManager.default.removeItem(atPath: "/tmp/snapshot-migration/\(outcome.report.runID)") }

    #expect(outcome.report.failedDeclarations > 0)
    #expect(outcome.report.applyLockAcquisitionFailed == false)
    #expect(outcome.report.filesApplyFailed == 0)
    #expect(outcome.exitCode == .migrationFailure)
  }

  @Test
  func lockContentionWithNoPendingAppliesStillExitsApplySafetyFailure() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    // No legacy declarations: the apply phase has nothing to write, so every
    // failure counter stays at zero — but the held lock must still fail the run.
    try fixture.write(
      path: "Tests/Modern.swift",
      contents: "import Testing\n\n@Test func modern() {}\n"
    )

    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { lock.release() }

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)

    #expect(outcome.exitCode == .applySafetyFailure)
    #expect(outcome.report.applyLockAcquisitionFailed)
    #expect(outcome.report.issueLines.contains { $0.contains("apply-lock-held") })
  }

  @Test
  func applyModeAppliesChangesAndCleansTempDirectoryOnSuccess() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Default")
      func profile() -> some View {
        Text("A")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Profile.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    let fileManager = FileManager.default
    let updated = try String(contentsOfFile: filePath, encoding: .utf8)

    #expect(outcome.exitCode == .success)
    #expect(outcome.report.reportSchemaVersion == 4)
    #expect(outcome.report.timings.total.wallSeconds > 0)
    #expect(outcome.report.timings.total.cpuSeconds >= 0)
    #expect(outcome.report.timings.scan.wallSeconds >= 0)
    #expect(outcome.report.timings.rewriteStage.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.cpuSeconds >= 0)
    #expect(updated.contains("@Test(\"Default\")"))
    #expect(updated.contains("#expectSnapshot(snapshotValue, named: \"Default\")"))
    #expect(!fileManager.fileExists(atPath: tempRoot))
    #expect(outcome.keptStagingRoot == nil)
  }

  @Test
  func surfacesUnreadableOversizeAndQualifiedFilesInsteadOfSilentSuccess() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(
      path: "build/Sources/BuildLegacy.swift",
      contents: """
      @SnapshotSuite
      struct BuildSnapshots {
        @SnapshotTest("Default")
        func card() -> some View {
          Text("A")
        }
      }
      """
    )
    var latin1Bytes = Data("@SnapshotTest func caf".utf8)
    latin1Bytes.append(0xE9)
    latin1Bytes.append(contentsOf: Data("() {}".utf8))
    try fixture.write(path: "Tests/Latin1.swift", data: latin1Bytes)
    let oversized = "@SnapshotTest func huge() {}\n" + String(repeating: "x", count: 4_096)
    try fixture.write(path: "Tests/Huge.swift", contents: oversized)
    try fixture.write(
      path: "Tests/Qualified.swift",
      contents: "@SnapshotsModule.SnapshotTest\nfunc qualified() -> some View { Text(\"A\") }"
    )

    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: true,
      maxFileSizeBytes: 512,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    defer { try? FileManager.default.removeItem(atPath: tempRoot) }

    #expect(outcome.exitCode == .strictSkipFailure)
    #expect(outcome.report.filesScanned == 4)
    #expect(outcome.report.migratedDeclarations == 1)
    #expect(outcome.report.skippedDeclarations == 1)
    #expect(outcome.report.filesUnreadable == 1)
    #expect(outcome.report.filesOversize == 1)
    #expect(
      outcome.report.issueLines.contains { $0.contains("Tests/Latin1.swift") && $0.contains("file-unreadable") }
    )
    #expect(
      outcome.report.issueLines.contains { $0.contains("Tests/Huge.swift") && $0.contains("file-oversize") }
    )
    #expect(
      outcome.report.issueLines.contains {
        $0.contains("Tests/Qualified.swift") && $0.contains("qualified-attribute-unsupported")
      }
    )
  }
}
