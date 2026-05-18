import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationRunnerIntegrationTests {
  @Test
  func dryRunProducesReportAndKeepsTempDirectory() async throws {
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
    #expect(outcome.report.reportSchemaVersion == 2)
    #expect(outcome.report.timings.total.wallSeconds > 0)
    #expect(outcome.report.timings.total.cpuSeconds >= 0)
    #expect(outcome.report.timings.scan.wallSeconds >= 0)
    #expect(outcome.report.timings.rewriteStage.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.wallSeconds == 0)
    #expect(outcome.report.timings.apply.cpuSeconds == 0)
    #expect(fileManager.fileExists(atPath: tempRoot))
    #expect(current == original)
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
    #expect(outcome.report.reportSchemaVersion == 2)
    #expect(outcome.report.timings.total.wallSeconds > 0)
    #expect(outcome.report.timings.total.cpuSeconds >= 0)
    #expect(outcome.report.timings.scan.wallSeconds >= 0)
    #expect(outcome.report.timings.rewriteStage.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.wallSeconds >= 0)
    #expect(outcome.report.timings.apply.cpuSeconds >= 0)
    #expect(updated.contains("@Test(\"Default\")"))
    #expect(updated.contains("#expectSnapshot(snapshotValue, named: \"Default\")"))
    #expect(!fileManager.fileExists(atPath: tempRoot))
  }
}
