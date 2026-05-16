public struct MigrationReport: Codable, Equatable {
  public let reportSchemaVersion: Int
  public let runID: String
  public let projectRoot: String
  public let filesScanned: Int
  public let candidateFiles: Int
  public let candidateDeclarations: Int
  public let migratedDeclarations: Int
  public let skippedDeclarations: Int
  public let failedDeclarations: Int
  public let migrationPercentage: Int
  public let filesAttemptedApply: Int
  public let filesApplied: Int
  public let filesApplyFailed: Int
  public let filesPreconditionFailed: Int
  public let filesUnsafeNonRegular: Int
  public let issueLines: [String]

  public init(
    reportSchemaVersion: Int,
    runID: String,
    projectRoot: String,
    filesScanned: Int,
    candidateFiles: Int,
    candidateDeclarations: Int,
    migratedDeclarations: Int,
    skippedDeclarations: Int,
    failedDeclarations: Int,
    migrationPercentage: Int,
    filesAttemptedApply: Int,
    filesApplied: Int,
    filesApplyFailed: Int,
    filesPreconditionFailed: Int,
    filesUnsafeNonRegular: Int,
    issueLines: [String] = []
  ) {
    self.reportSchemaVersion = reportSchemaVersion
    self.runID = runID
    self.projectRoot = projectRoot
    self.filesScanned = filesScanned
    self.candidateFiles = candidateFiles
    self.candidateDeclarations = candidateDeclarations
    self.migratedDeclarations = migratedDeclarations
    self.skippedDeclarations = skippedDeclarations
    self.failedDeclarations = failedDeclarations
    self.migrationPercentage = migrationPercentage
    self.filesAttemptedApply = filesAttemptedApply
    self.filesApplied = filesApplied
    self.filesApplyFailed = filesApplyFailed
    self.filesPreconditionFailed = filesPreconditionFailed
    self.filesUnsafeNonRegular = filesUnsafeNonRegular
    self.issueLines = issueLines
  }

  public func resolveExitCode(failOnSkips: Bool) -> MigrationExitCode {
    if filesApplyFailed > 0 || filesPreconditionFailed > 0 || filesUnsafeNonRegular > 0 {
      return .applySafetyFailure
    }
    if failedDeclarations > 0 {
      return .migrationFailure
    }
    if failOnSkips && skippedDeclarations > 0 {
      return .strictSkipFailure
    }
    return .success
  }
}
