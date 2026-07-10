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
  func helpPrintsEveryFlagAndTheExitCodeLadderAndExitsZero() async {
    var lines: [String] = []
    var errorLines: [String] = []
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: ["--help"],
      emitLine: { lines.append($0) },
      emitErrorLine: { errorLines.append($0) }
    )

    #expect(exitCode == 0)
    #expect(errorLines.isEmpty)

    let helpText = lines.joined(separator: "\n")
    let documentedFlags = [
      "--project-root",
      "--apply",
      "--json-report",
      "--keep-temp",
      "--fail-on-skips",
      "--max-file-size-bytes",
      "--max-staged-bytes",
      "--apply-lock-timeout-seconds",
      "--help",
    ]
    for flag in documentedFlags {
      #expect(helpText.contains(flag), "help text must document \(flag)")
    }
    for exitCodeDescription in [
      "0", "success",
      "1", "migration failure",
      "2", "apply safety failure",
      "3", "invalid usage",
      "4", "strict skip failure",
    ] {
      #expect(
        helpText.lowercased().contains(exitCodeDescription),
        "help text must document exit code entry '\(exitCodeDescription)'"
      )
    }
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
