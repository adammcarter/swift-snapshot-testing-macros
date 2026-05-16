public enum MigrationMode: Equatable {
  case dryRun
  case apply
}

public struct MigrationOptions: Equatable {
  public let projectRoot: String
  public let mode: MigrationMode
  public let jsonReportPath: String?
  public let keepTemp: Bool
  public let failOnSkips: Bool
  public let maxFileSizeBytes: Int
  public let maxStagedBytes: Int
  public let applyLockTimeoutSeconds: Int

  public init(
    projectRoot: String,
    mode: MigrationMode,
    jsonReportPath: String?,
    keepTemp: Bool,
    failOnSkips: Bool,
    maxFileSizeBytes: Int,
    maxStagedBytes: Int,
    applyLockTimeoutSeconds: Int
  ) {
    self.projectRoot = projectRoot
    self.mode = mode
    self.jsonReportPath = jsonReportPath
    self.keepTemp = keepTemp
    self.failOnSkips = failOnSkips
    self.maxFileSizeBytes = maxFileSizeBytes
    self.maxStagedBytes = maxStagedBytes
    self.applyLockTimeoutSeconds = applyLockTimeoutSeconds
  }
}

public enum MigrationCLIError: Error, Equatable {
  case missingProjectRoot
  case missingOptionValue(String)
  case invalidIntegerOption(String)
}
