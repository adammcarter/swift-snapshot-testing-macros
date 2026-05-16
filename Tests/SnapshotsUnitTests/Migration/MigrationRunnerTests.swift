import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationRunnerTests {
  @Test
  func invalidProjectRootReturnsMigrationFailure() async throws {
    let missingRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("missing-root-\(UUID().uuidString)", isDirectory: true).path

    let options = MigrationOptions(
      projectRoot: missingRoot,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let exitCode = try await MigrationRunner().run(options: options)
    #expect(exitCode == .migrationFailure)
  }
}
