public struct ConsoleReporter {
  public init() {}

  public func summaryLines(report: MigrationReport) -> [String] {
    [
      "files scanned: \(report.filesScanned)",
      "candidate declarations: \(report.candidateDeclarations)",
      "migrated/skipped/failed: \(report.migratedDeclarations)/\(report.skippedDeclarations)/\(report.failedDeclarations)",
      "migration percentage: \(report.migrationPercentage)%",
      "apply attempted/applied/failed: \(report.filesAttemptedApply)/\(report.filesApplied)/\(report.filesApplyFailed)",
    ]
  }

  public func printSummary(report: MigrationReport, maxIssues: Int = 50) {
    for line in summaryLines(report: report) {
      print(line)
    }

    for issue in report.issueLines.sorted().prefix(maxIssues) {
      print(issue)
    }
  }
}
