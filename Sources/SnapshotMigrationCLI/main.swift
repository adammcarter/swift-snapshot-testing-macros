import Foundation
import SnapshotMigrationSupport

@main
enum SnapshotMigrationCLI {
  static func main() {
    do {
      _ = try MigrationOptionsParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
      exit(1)
    } catch {
      fputs("migration error: \(error)\n", stderr)
      exit(3)
    }
  }
}
