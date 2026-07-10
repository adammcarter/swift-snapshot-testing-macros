import Foundation
import SnapshotMigrationSupport

@main
enum SnapshotMigrationCLI {
  static func main() async {
    do {
      let options = try MigrationOptionsParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
      let outcome = try await MigrationRunner().runWithOutcome(options: options)

      let consoleReporter = ConsoleReporter()
      consoleReporter.printSummary(report: outcome.report, maxIssues: 50)

      if let keptStagingRoot = outcome.keptStagingRoot {
        print("staged rewrites kept at: \(keptStagingRoot)")
      }

      if let jsonReportPath = options.jsonReportPath {
        try JSONReporter().write(report: outcome.report, to: jsonReportPath)
      }

      exit(Int32(outcome.exitCode.rawValue))
    } catch let error as MigrationCLIError {
      fputs("migration error: \(userFacingMessage(for: error))\n", stderr)
      exit(3)
    } catch {
      fputs("migration error: unexpected failure: \(error)\n", stderr)
      exit(3)
    }
  }

  private static func userFacingMessage(for error: MigrationCLIError) -> String {
    switch error {
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
