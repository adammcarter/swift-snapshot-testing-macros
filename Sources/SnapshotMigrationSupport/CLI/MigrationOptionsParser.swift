public enum MigrationOptionsParser {
  public static func parse(arguments: [String]) throws -> MigrationOptions {
    var projectRoot: String?
    var mode: MigrationMode = .dryRun
    var jsonReportPath: String?
    var keepTemp = false
    var failOnSkips = false
    var maxFileSizeBytes = 2_000_000
    var maxStagedBytes = 536_870_912
    var applyLockTimeoutSeconds = 0

    var index = 0
    while index < arguments.count {
      switch arguments[index] {
      case "--project-root":
        index += 1
        guard index < arguments.count, !arguments[index].hasPrefix("--") else {
          throw MigrationCLIError.missingOptionValue("--project-root")
        }
        projectRoot = arguments[index]
      case "--apply":
        mode = .apply
      case "--json-report":
        index += 1
        guard index < arguments.count, !arguments[index].hasPrefix("--") else {
          throw MigrationCLIError.missingOptionValue("--json-report")
        }
        jsonReportPath = arguments[index]
      case "--keep-temp":
        keepTemp = true
      case "--fail-on-skips":
        failOnSkips = true
      case "--max-file-size-bytes":
        index += 1
        guard index < arguments.count, !arguments[index].hasPrefix("--"), let value = Int(arguments[index]) else {
          throw MigrationCLIError.invalidIntegerOption("--max-file-size-bytes")
        }
        maxFileSizeBytes = value
      case "--max-staged-bytes":
        index += 1
        guard index < arguments.count, !arguments[index].hasPrefix("--"), let value = Int(arguments[index]) else {
          throw MigrationCLIError.invalidIntegerOption("--max-staged-bytes")
        }
        maxStagedBytes = value
      case "--apply-lock-timeout-seconds":
        index += 1
        guard index < arguments.count, !arguments[index].hasPrefix("--"), let value = Int(arguments[index]) else {
          throw MigrationCLIError.invalidIntegerOption("--apply-lock-timeout-seconds")
        }
        applyLockTimeoutSeconds = value
      default:
        throw MigrationCLIError.unknownOption(arguments[index])
      }

      index += 1
    }

    guard let projectRoot else {
      throw MigrationCLIError.missingProjectRoot
    }

    return MigrationOptions(
      projectRoot: projectRoot,
      mode: mode,
      jsonReportPath: jsonReportPath,
      keepTemp: keepTemp,
      failOnSkips: failOnSkips,
      maxFileSizeBytes: maxFileSizeBytes,
      maxStagedBytes: maxStagedBytes,
      applyLockTimeoutSeconds: applyLockTimeoutSeconds
    )
  }
}
