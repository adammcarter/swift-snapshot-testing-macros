import Foundation

public struct ConsoleReporter {
  public init() {}

  public func summaryLines(report: MigrationReport) -> [String] {
    [
      "files scanned: \(report.filesScanned)",
      "files unreadable/oversize: \(report.filesUnreadable)/\(report.filesOversize)",
      "candidate declarations: \(report.candidateDeclarations)",
      "migrated/skipped/failed: \(report.migratedDeclarations)/\(report.skippedDeclarations)/\(report.failedDeclarations)",
      "migration percentage: \(report.migrationPercentage)%",
      "apply attempted/applied/failed: \(report.filesAttemptedApply)/\(report.filesApplied)/\(report.filesApplyFailed)",
      "timings:",
      "  total wall: \(format(report.timings.total.wallSeconds))",
      "  total cpu: \(format(report.timings.total.cpuSeconds))",
      "  scan: wall \(format(report.timings.scan.wallSeconds)), cpu \(format(report.timings.scan.cpuSeconds))",
      "  rewrite/stage: wall \(format(report.timings.rewriteStage.wallSeconds)), cpu \(format(report.timings.rewriteStage.cpuSeconds))",
      "  apply: wall \(format(report.timings.apply.wallSeconds)), cpu \(format(report.timings.apply.cpuSeconds))",
    ]
  }

  public func printSummary(
    report: MigrationReport,
    maxIssues: Int = 50,
    emit: (String) -> Void = { print($0) }
  ) {
    for line in summaryLines(report: report) {
      emit(line)
    }

    for issue in report.issueLines.sorted().prefix(maxIssues) {
      emit(issue)
    }
  }

  private func format(_ seconds: Double) -> String {
    String(format: "%.3fs", locale: Locale(identifier: "en_US_POSIX"), seconds)
  }
}
