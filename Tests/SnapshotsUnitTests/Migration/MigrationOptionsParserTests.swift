import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationOptionsParserTests {
  @Test
  func requiresProjectRoot() {
    #expect(throws: MigrationCLIError.self) {
      _ = try MigrationOptionsParser.parse(arguments: [])
    }
  }

  @Test
  func defaultsAreDryRunAndSpecDefaults() throws {
    let options = try MigrationOptionsParser.parse(arguments: ["--project-root", "/tmp/example"])

    #expect(options.mode == .dryRun)
    #expect(options.maxFileSizeBytes == 2_000_000)
    #expect(options.maxStagedBytes == 536_870_912)
    #expect(options.applyLockTimeoutSeconds == 0)
    #expect(options.failOnSkips == false)
  }

  @Test
  func applyModeAndJsonReport() throws {
    let options = try MigrationOptionsParser.parse(arguments: [
      "--project-root", "/tmp/example",
      "--apply",
      "--json-report", "report.json",
      "--keep-temp",
      "--fail-on-skips",
    ])

    #expect(options.mode == .apply)
    #expect(options.keepTemp == true)
    #expect(options.failOnSkips == true)
    #expect(options.jsonReportPath == "report.json")
  }
}
