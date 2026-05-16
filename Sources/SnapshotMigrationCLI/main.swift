import Foundation
import SnapshotMigrationSupport

@main
enum SnapshotMigrationCLI {
  static func main() {
    do {
      _ = try MigrationOptionsParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
      exit(1)
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
