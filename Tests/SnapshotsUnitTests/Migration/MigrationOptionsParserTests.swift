import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationOptionsParserTests {
  @Test
  func requiresProjectRoot() {
    assertParseError(arguments: [], expected: .missingProjectRoot)
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

  @Test
  func missingProjectRootValueReturnsError() {
    assertParseError(arguments: ["--project-root"], expected: .missingOptionValue("--project-root"))
  }

  @Test
  func projectRootValueCannotBeAnotherOption() {
    assertParseError(arguments: ["--project-root", "--apply"], expected: .missingOptionValue("--project-root"))
  }

  @Test
  func missingJsonReportValueReturnsError() {
    assertParseError(arguments: ["--project-root", "/tmp/example", "--json-report"], expected: .missingOptionValue("--json-report"))
  }

  @Test
  func jsonReportValueCannotBeAnotherOption() {
    assertParseError(
      arguments: ["--project-root", "/tmp/example", "--json-report", "--apply"],
      expected: .missingOptionValue("--json-report")
    )
  }

  @Test
  func invalidIntegerOptionReturnsError() {
    assertParseError(arguments: ["--project-root", "/tmp/example", "--max-file-size-bytes", "abc"], expected: .invalidIntegerOption("--max-file-size-bytes"))
    assertParseError(arguments: ["--project-root", "/tmp/example", "--max-staged-bytes", "abc"], expected: .invalidIntegerOption("--max-staged-bytes"))
    assertParseError(arguments: ["--project-root", "/tmp/example", "--apply-lock-timeout-seconds", "abc"], expected: .invalidIntegerOption("--apply-lock-timeout-seconds"))
  }

  @Test
  func integerOptionValueCannotBeAnotherOption() {
    assertParseError(
      arguments: ["--project-root", "/tmp/example", "--max-file-size-bytes", "--apply"],
      expected: .invalidIntegerOption("--max-file-size-bytes")
    )
    assertParseError(
      arguments: ["--project-root", "/tmp/example", "--max-staged-bytes", "--apply"],
      expected: .invalidIntegerOption("--max-staged-bytes")
    )
    assertParseError(
      arguments: ["--project-root", "/tmp/example", "--apply-lock-timeout-seconds", "--apply"],
      expected: .invalidIntegerOption("--apply-lock-timeout-seconds")
    )
  }

  @Test
  func acceptsExplicitNumericOverrides() throws {
    let options = try MigrationOptionsParser.parse(arguments: [
      "--project-root", "/tmp/example",
      "--max-file-size-bytes", "100",
      "--max-staged-bytes", "200",
      "--apply-lock-timeout-seconds", "3",
    ])

    #expect(options.maxFileSizeBytes == 100)
    #expect(options.maxStagedBytes == 200)
    #expect(options.applyLockTimeoutSeconds == 3)
  }

  @Test
  func unknownOptionReturnsDedicatedError() {
    assertParseError(arguments: ["--project-root", "/tmp/example", "--bogus"], expected: .unknownOption("--bogus"))
  }

  private func assertParseError(arguments: [String], expected: MigrationCLIError) {
    do {
      _ = try MigrationOptionsParser.parse(arguments: arguments)
      Issue.record("Expected parse to throw \(expected), but it succeeded")
    } catch let error as MigrationCLIError {
      #expect(error == expected)
    } catch {
      Issue.record("Expected MigrationCLIError \(expected), but got \(error)")
    }
  }
}
