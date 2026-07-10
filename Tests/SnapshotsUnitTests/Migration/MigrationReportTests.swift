import Foundation
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

  @Test
  func strictSkipFailureCoversUnreadableAndOversizeFiles() {
    let unreadable = MigrationReport(
      reportSchemaVersion: 3,
      runID: "r4",
      projectRoot: "/tmp/project",
      filesScanned: 2,
      candidateFiles: 1,
      candidateDeclarations: 1,
      migratedDeclarations: 1,
      skippedDeclarations: 0,
      failedDeclarations: 0,
      migrationPercentage: 100,
      filesAttemptedApply: 0,
      filesApplied: 0,
      filesApplyFailed: 0,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0,
      filesUnreadable: 1,
      filesOversize: 0
    )

    #expect(unreadable.resolveExitCode(failOnSkips: true) == .strictSkipFailure)
    #expect(unreadable.resolveExitCode(failOnSkips: false) == .success)

    let oversize = MigrationReport(
      reportSchemaVersion: 3,
      runID: "r5",
      projectRoot: "/tmp/project",
      filesScanned: 2,
      candidateFiles: 1,
      candidateDeclarations: 1,
      migratedDeclarations: 1,
      skippedDeclarations: 0,
      failedDeclarations: 0,
      migrationPercentage: 100,
      filesAttemptedApply: 0,
      filesApplied: 0,
      filesApplyFailed: 0,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0,
      filesUnreadable: 0,
      filesOversize: 1
    )

    #expect(oversize.resolveExitCode(failOnSkips: true) == .strictSkipFailure)
    #expect(oversize.resolveExitCode(failOnSkips: false) == .success)
  }

  @Test
  func lockAcquisitionFailureAlwaysResolvesToApplySafetyFailure() {
    // A lock failure with zero pending applies leaves every failure counter at
    // zero; the dedicated flag must still force the apply-safety exit code.
    let report = MigrationReport(
      reportSchemaVersion: 4,
      runID: "r6",
      projectRoot: "/tmp/project",
      filesScanned: 1,
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
      filesUnsafeNonRegular: 0,
      applyLockAcquisitionFailed: true
    )

    #expect(report.resolveExitCode(failOnSkips: false) == .applySafetyFailure)
    #expect(report.resolveExitCode(failOnSkips: true) == .applySafetyFailure)
  }

  @Test
  func timingsRoundTripThroughCodableAndEquality() throws {
    let report = MigrationReport(
      reportSchemaVersion: 2,
      runID: "timed",
      projectRoot: "/tmp/project",
      filesScanned: 4,
      candidateFiles: 2,
      candidateDeclarations: 2,
      migratedDeclarations: 2,
      skippedDeclarations: 0,
      failedDeclarations: 0,
      migrationPercentage: 100,
      filesAttemptedApply: 2,
      filesApplied: 2,
      filesApplyFailed: 0,
      filesPreconditionFailed: 0,
      filesUnsafeNonRegular: 0,
      issueLines: [],
      timings: .init(
        total: .init(wallSeconds: 1.0, cpuSeconds: 0.5),
        scan: .init(wallSeconds: 0.1, cpuSeconds: 0.05),
        rewriteStage: .init(wallSeconds: 0.8, cpuSeconds: 0.4),
        apply: .init(wallSeconds: 0.1, cpuSeconds: 0.05)
      )
    )

    let data = try JSONEncoder().encode(report)
    let decoded = try JSONDecoder().decode(MigrationReport.self, from: data)

    #expect(decoded == report)
  }
}
