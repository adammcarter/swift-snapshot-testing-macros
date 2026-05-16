import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationReportTests {
  @Test
  func percentageIs100WhenNoCandidateDeclarations() {
    let report = MigrationReport(
      reportSchemaVersion: 1,
      runID: "r1",
      projectRoot: "/tmp/project",
      filesScanned: 0,
      candidateFiles: 0,
      candidateDeclarations: 0,
      migratedDeclarations: 0,
      skippedDeclarations: 0,
      failedDeclarations: 0,
      migrationPercentage: 100,
      filesAttemptedApply: 0,
      filesApplied: 0,
      filesApplyFailed: 0,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0
    )

    #expect(report.migrationPercentage == 100)
  }

  @Test
  func exitPrecedencePrefersApplyFailuresOverMigrationFailures() {
    let report = MigrationReport(
      reportSchemaVersion: 1,
      runID: "r2",
      projectRoot: "/tmp/project",
      filesScanned: 4,
      candidateFiles: 2,
      candidateDeclarations: 2,
      migratedDeclarations: 0,
      skippedDeclarations: 1,
      failedDeclarations: 1,
      migrationPercentage: 0,
      filesAttemptedApply: 2,
      filesApplied: 1,
      filesApplyFailed: 1,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0
    )

    #expect(report.resolveExitCode(failOnSkips: true) == .applySafetyFailure)
  }

  @Test
  func exitPrecedenceSupportsStrictSkipFailure() {
    let report = MigrationReport(
      reportSchemaVersion: 1,
      runID: "r3",
      projectRoot: "/tmp/project",
      filesScanned: 2,
      candidateFiles: 2,
      candidateDeclarations: 2,
      migratedDeclarations: 1,
      skippedDeclarations: 1,
      failedDeclarations: 0,
      migrationPercentage: 50,
      filesAttemptedApply: 0,
      filesApplied: 0,
      filesApplyFailed: 0,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0
    )

    #expect(report.resolveExitCode(failOnSkips: true) == .strictSkipFailure)
    #expect(report.resolveExitCode(failOnSkips: false) == .success)
  }
}
