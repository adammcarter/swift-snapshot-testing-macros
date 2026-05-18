import Testing

@testable import SnapshotMigrationSupport

@Suite
struct ConsoleReporterTests {
  @Test
  func summaryLinesAppendTimingBlockInExpectedOrder() {
    let report = MigrationReport(
      reportSchemaVersion: 2,
      runID: "run-1",
      projectRoot: "/tmp/project",
      filesScanned: 3,
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
      filesUnsafeNonRegular: 0,
      issueLines: [],
      timings: .init(
        total: .init(wallSeconds: 1.423, cpuSeconds: 0.981),
        scan: .init(wallSeconds: 0.114, cpuSeconds: 0.089),
        rewriteStage: .init(wallSeconds: 1.242, cpuSeconds: 0.861),
        apply: .init(wallSeconds: 0, cpuSeconds: 0)
      )
    )

    #expect(
      ConsoleReporter().summaryLines(report: report) == [
        "files scanned: 3",
        "candidate declarations: 2",
        "migrated/skipped/failed: 1/1/0",
        "migration percentage: 50%",
        "apply attempted/applied/failed: 0/0/0",
        "timings:",
        "  total wall: 1.423s",
        "  total cpu: 0.981s",
        "  scan: wall 0.114s, cpu 0.089s",
        "  rewrite/stage: wall 1.242s, cpu 0.861s",
        "  apply: wall 0.000s, cpu 0.000s",
      ]
    )
  }
}
