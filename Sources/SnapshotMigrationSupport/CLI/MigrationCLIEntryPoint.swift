import Foundation

/// The migration CLI's logic, extracted from the executable's `main` so the
/// argument-parsing, reporting, and exit-code paths are testable. The
/// executable target stays a thin wrapper that forwards `CommandLine`
/// arguments and calls `exit` with the returned code.
public enum MigrationCLIEntryPoint {
  public static func run(
    arguments: [String],
    emitLine: (String) -> Void = { print($0) },
    emitErrorLine: (String) -> Void = { fputs("\($0)\n", stderr) }
  ) async -> Int32 {
    do {
      let options = try MigrationOptionsParser.parse(arguments: arguments)
      let outcome = try await MigrationRunner().runWithOutcome(options: options)

      ConsoleReporter().printSummary(report: outcome.report, maxIssues: 50, emit: emitLine)

      if let keptStagingRoot = outcome.keptStagingRoot {
        emitLine("staged rewrites kept at: \(keptStagingRoot)")
      }

      if let jsonReportPath = options.jsonReportPath {
        do {
          try JSONReporter().write(report: outcome.report, to: jsonReportPath)
        } catch {
          // The migration run itself already finished; a report-write failure
          // must not be misreported as invalid usage (exit 3), and it must not
          // mask what the run did. State plainly whether files were changed and
          // exit with at least migrationFailure, preserving any more severe
          // exit code the run itself resolved.
          let runOutcomeDescription =
            outcome.report.filesApplied > 0
            ? "changes WERE applied to \(outcome.report.filesApplied) file(s)"
            : "no files were modified by this run"
          emitErrorLine(
            "migration error: failed to write JSON report to \(jsonReportPath): \(error)"
          )
          emitErrorLine(
            "migration error: the migration run itself completed (\(runOutcomeDescription)); "
              + "only the JSON report is missing"
          )
          return Int32(max(outcome.exitCode.rawValue, MigrationExitCode.migrationFailure.rawValue))
        }
      }

      return Int32(outcome.exitCode.rawValue)
    } catch MigrationCLIError.helpRequested {
      for line in helpLines {
        emitLine(line)
      }
      return Int32(MigrationExitCode.success.rawValue)
    } catch let error as MigrationCLIError {
      emitErrorLine("migration error: \(userFacingMessage(for: error))")
      return Int32(MigrationExitCode.invalidUsage.rawValue)
    } catch {
      emitErrorLine("migration error: unexpected failure: \(error)")
      return Int32(MigrationExitCode.invalidUsage.rawValue)
    }
  }

  /// The `--help` output. Every flag the parser accepts and every exit code the
  /// runner can resolve must appear here; `MigrationCLIEntryPointTests` locks that.
  private static let helpLines = [
    "usage: migrate-snapshot-tests --project-root <path> [options]",
    "",
    "Migrates legacy @SnapshotSuite/@SnapshotTest declarations to @Suite/@Test",
    "with #expectSnapshot(...). Defaults to dry-run: no files are modified",
    "unless --apply is passed.",
    "",
    "options:",
    "  --project-root <path>             Root of the project to scan (required).",
    "  --apply                           Write the migrated files (default: dry-run).",
    "  --json-report <path>              Write the full machine-readable report to <path>.",
    "  --keep-temp                       Keep the run's staging directory under",
    "                                    /tmp/snapshot-migration for inspection.",
    "  --fail-on-skips                   Exit 4 when any declaration is skipped or any",
    "                                    file is unreadable or oversize.",
    "  --max-file-size-bytes <bytes>     Exclude files larger than <bytes> (default: 2000000).",
    "  --max-staged-bytes <bytes>        Fail the run when staged rewritten copies exceed",
    "                                    <bytes> in total (default: 536870912).",
    "  --apply-lock-timeout-seconds <s>  Wait up to <s> seconds for the apply lock (default: 0).",
    "  --help, -h                        Show this help and exit.",
    "",
    "exit codes:",
    "  0  success",
    "  1  migration failure (rewrite/staging errors; also the JSON-report-write fallback)",
    "  2  apply safety failure (precondition, atomic replace, non-regular file, or apply lock)",
    "  3  invalid usage",
    "  4  strict skip failure (--fail-on-skips with skipped, unreadable, or oversize files)",
  ]

  private static func userFacingMessage(for error: MigrationCLIError) -> String {
    switch error {
    case .helpRequested:
      // Handled by the dedicated catch in `run`; kept for switch exhaustiveness.
      return "help requested"
    case .missingProjectRoot:
      return "missing required option --project-root <path>"
    case .missingOptionValue(let option):
      return "missing value for option \(option)"
    case .invalidIntegerOption(let option):
      return "invalid integer for option \(option)"
    case .unknownOption(let option):
      return "unknown option \(option)"
    }
  }
}
