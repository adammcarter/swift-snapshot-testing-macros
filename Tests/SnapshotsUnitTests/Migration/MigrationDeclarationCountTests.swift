import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationDeclarationCountTests {
  @Test
  func fileWithTwoDeclarationsCountsEachDeclaration() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("First")
      func first() -> some View {
        Text("A")
      }

      @SnapshotTest("Second")
      func second() -> some View {
        Text("B")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Profile.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    defer { try? FileManager.default.removeItem(atPath: tempRoot) }

    let updated = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(outcome.exitCode == .success)
    #expect(outcome.report.candidateFiles == 1)
    #expect(outcome.report.candidateDeclarations == 2)
    #expect(outcome.report.migratedDeclarations == 2)
    #expect(outcome.report.skippedDeclarations == 0)
    #expect(outcome.report.failedDeclarations == 0)
    #expect(outcome.report.migrationPercentage == 100)
    #expect(outcome.report.filesApplied == 1)
    #expect(updated.contains("@Test(\"First\")"))
    #expect(updated.contains("@Test(\"Second\")"))
  }

  @Test
  func commentAndStringOnlyMatchesContributeZeroDeclarationsAndNoSkip() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    // This file mentions @SnapshotTest only inside a comment.
    let marker = "@SnapshotSuite"

    func plain() {}
    """

    let filePath = try fixture.write(path: "Tests/CommentOnly.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .dryRun,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: true,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    defer { try? FileManager.default.removeItem(atPath: tempRoot) }

    let current = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(outcome.exitCode == .success)
    #expect(outcome.report.candidateFiles == 0)
    #expect(outcome.report.candidateDeclarations == 0)
    #expect(outcome.report.migratedDeclarations == 0)
    #expect(outcome.report.skippedDeclarations == 0)
    #expect(outcome.report.failedDeclarations == 0)
    #expect(outcome.report.migrationPercentage == 100)
    #expect(outcome.report.issueLines.isEmpty)
    #expect(current == original)
  }

  @Test
  func mixedFileReportsPerDeclarationReasonsAndIsNotApplied() async throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let original = """
    @SnapshotSuite
    struct MixedSnapshots {
      @SnapshotTest("Good")
      func good() -> some View {
        Text("A")
      }

      @SnapshotTest("Bad")
      func bad(value: Int) -> some View {
        Text("B")
      }
    }
    """

    let filePath = try fixture.write(path: "Tests/Mixed.swift", contents: original)
    let options = MigrationOptions(
      projectRoot: fixture.root,
      mode: .apply,
      jsonReportPath: nil,
      keepTemp: false,
      failOnSkips: false,
      maxFileSizeBytes: 2_000_000,
      maxStagedBytes: 536_870_912,
      applyLockTimeoutSeconds: 0
    )

    let outcome = try await MigrationRunner().runWithOutcome(options: options)
    let tempRoot = "/tmp/snapshot-migration/\(outcome.report.runID)"
    defer { try? FileManager.default.removeItem(atPath: tempRoot) }

    let current = try String(contentsOfFile: filePath, encoding: .utf8)
    #expect(outcome.report.candidateFiles == 1)
    #expect(outcome.report.candidateDeclarations == 2)
    #expect(outcome.report.migratedDeclarations == 0)
    #expect(outcome.report.skippedDeclarations == 2)
    #expect(outcome.report.failedDeclarations == 0)
    #expect(outcome.report.migrationPercentage == 0)
    #expect(outcome.report.filesAttemptedApply == 0)
    #expect(outcome.report.filesApplied == 0)
    #expect(current == original)
    #expect(
      outcome.report.issueLines.contains {
        $0.contains("Tests/Mixed.swift") && $0.contains(" bad ") && $0.contains("unsupported-signature-shape")
      }
    )
    #expect(
      outcome.report.issueLines.contains {
        $0.contains("Tests/Mixed.swift")
          && $0.contains(" good ")
          && $0.contains("blocked-by-sibling-skip")
          && $0.contains("bad")
      }
    )
  }
}
