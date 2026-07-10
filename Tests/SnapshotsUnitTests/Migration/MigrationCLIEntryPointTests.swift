import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationCLIEntryPointTests {
  private let legacySource = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Default")
      func profile() -> some View {
        Text("A")
      }
    }
    """

  @Test
  func jsonReportWriteFailureAfterSuccessfulApplyExitsMigrationFailureAndSaysChangesWereApplied() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    let filePath = try fixture.write(path: "Tests/Profile.swift", contents: legacySource)

    // Parent directory does not exist, so the JSON report write must fail
    // after the apply itself has already succeeded.
    let unwritableReportPath = URL(fileURLWithPath: fixture.root)
      .appendingPathComponent("missing-report-dir/report.json").path

    var errorLines: [String] = []
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: ["--project-root", fixture.root, "--apply", "--json-report", unwritableReportPath],
      emitLine: { _ in },
      emitErrorLine: { errorLines.append($0) }
    )

    let updated = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(updated.contains("#expectSnapshot"), "the apply itself must have succeeded")
    #expect(exitCode == Int32(MigrationExitCode.migrationFailure.rawValue))
    #expect(exitCode != Int32(MigrationExitCode.invalidUsage.rawValue))
    #expect(errorLines.contains { $0.contains("changes WERE applied") })
  }

  @Test
  func jsonReportWriteFailureAfterCleanDryRunExitsMigrationFailureAndSaysNothingWasModified() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(path: "Tests/Profile.swift", contents: legacySource)

    let unwritableReportPath = URL(fileURLWithPath: fixture.root)
      .appendingPathComponent("missing-report-dir/report.json").path

    var errorLines: [String] = []
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: ["--project-root", fixture.root, "--json-report", unwritableReportPath],
      emitLine: { _ in },
      emitErrorLine: { errorLines.append($0) }
    )

    #expect(exitCode == Int32(MigrationExitCode.migrationFailure.rawValue))
    #expect(errorLines.contains { $0.contains("no files were modified") })
  }

  @Test
  func jsonReportWriteFailurePreservesMoreSevereRunExitCode() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(
      path: "Tests/Modern.swift",
      contents: "import Testing\n\n@Test func modern() {}\n"
    )

    // Held lock makes the apply run itself exit applySafetyFailure (2); the
    // report-write failure must not downgrade that to migrationFailure (1)
    // or misclassify it as invalid usage (3).
    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { lock.release() }

    let unwritableReportPath = URL(fileURLWithPath: fixture.root)
      .appendingPathComponent("missing-report-dir/report.json").path

    var errorLines: [String] = []
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: ["--project-root", fixture.root, "--apply", "--json-report", unwritableReportPath],
      emitLine: { _ in },
      emitErrorLine: { errorLines.append($0) }
    )

    #expect(exitCode == Int32(MigrationExitCode.applySafetyFailure.rawValue))
    #expect(errorLines.contains { $0.contains("JSON report") })
  }

  @Test
  func invalidUsageStillExitsInvalidUsage() async {
    var errorLines: [String] = []
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: ["--unknown-option"],
      emitLine: { _ in },
      emitErrorLine: { errorLines.append($0) }
    )

    #expect(exitCode == Int32(MigrationExitCode.invalidUsage.rawValue))
    #expect(errorLines.contains { $0.contains("unknown option") })
  }
}
