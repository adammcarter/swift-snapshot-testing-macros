import Foundation
import SnapshotMigrationSupport

@main
enum SnapshotMigrationCLI {
  static func main() async {
    let exitCode = await MigrationCLIEntryPoint.run(
      arguments: Array(CommandLine.arguments.dropFirst())
    )
    exit(exitCode)
  }
}
