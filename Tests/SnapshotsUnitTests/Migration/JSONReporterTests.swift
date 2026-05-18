import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct JSONReporterTests {
  @Test
  func writeIncludesTimingPayloadAndSchemaVersion2() throws {
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

    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appending(path: UUID().uuidString)
      .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: outputURL) }

    try JSONReporter().write(report: report, to: outputURL.path)

    let data = try Data(contentsOf: outputURL)
    let payload = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let timings = try #require(payload["timings"] as? [String: Any])
    let rewriteStage = try #require(timings["rewriteStage"] as? [String: Any])

    #expect(payload["reportSchemaVersion"] as? Int == 2)
    #expect(rewriteStage["wallSeconds"] as? Double == 1.242)
    #expect(rewriteStage["cpuSeconds"] as? Double == 0.861)
  }
}
