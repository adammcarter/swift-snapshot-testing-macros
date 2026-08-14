#if os(macOS)
import Foundation
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// The record-mode contract end to end through the asserter: for each pointfree record mode
/// and each starting state of the reference on disk, how many failures are reported and what
/// the reference looks like afterwards.
///
/// `RecordSnapshotTraitTests` covers the trait plumbing (task-local propagation) and
/// `AmbientPointfreeConfigurationTests` covers a few ambient-vs-trait cells. This pins the
/// whole matrix, and in particular the two cells that are easiest to get wrong: `.all`
/// rewrites even a reference that already matches (so it always reports a failure), and
/// `.missing` never rewrites a reference that already exists (so a mismatch is reported, not
/// silently re-recorded over).
///
/// Uses pointfree's deterministic `.lines` text strategy, so the matrix needs no rendering and
/// no simulator.
@MainActor
struct SnapshotRecordModeTests {
  private static let content = "record-mode matrix content"
  private static let mismatchingContent = "a different, already-recorded reference"
  private static let referenceFileName = "sharedName.1.txt"

  /// The reference on disk when the assertion runs.
  enum Precondition: Sendable {
    case absent           // nothing recorded yet
    case matching         // a reference that matches the render
    case mismatching      // a reference that differs from the render
  }

  /// What the reference should be afterwards.
  enum Expected: Sendable {
    case absent           // still nothing on disk
    case canonical        // the render's own content (freshly recorded or unchanged)
    case mismatching      // the pre-existing mismatching content, left untouched
  }

  struct Case: Sendable, CustomTestStringConvertible {
    let label: String
    let mode: RecordSnapshotTrait.RecordKind
    let precondition: Precondition
    let expectedFailures: Int
    let expectedAfter: Expected

    var testDescription: String { label }
  }

  @Test(arguments: [
    // .never — never writes. A present-and-matching reference passes; everything else fails
    // without touching disk.
    Case(label: ".never + absent → fails, records nothing", mode: .never, precondition: .absent, expectedFailures: 1, expectedAfter: .absent),
    Case(label: ".never + matching → passes", mode: .never, precondition: .matching, expectedFailures: 0, expectedAfter: .canonical),
    Case(label: ".never + mismatching → fails, leaves reference", mode: .never, precondition: .mismatching, expectedFailures: 1, expectedAfter: .mismatching),

    // .missing — writes only when there is nothing there. Crucially it does NOT re-record over
    // an existing mismatching reference; that mismatch is a real failure.
    Case(label: ".missing + absent → records, fails once", mode: .missing, precondition: .absent, expectedFailures: 1, expectedAfter: .canonical),
    Case(label: ".missing + matching → passes, unchanged", mode: .missing, precondition: .matching, expectedFailures: 0, expectedAfter: .canonical),
    Case(label: ".missing + mismatching → fails, does NOT re-record", mode: .missing, precondition: .mismatching, expectedFailures: 1, expectedAfter: .mismatching),

    // .all — always writes, even when the reference already matched. Every run is a failure and
    // every run overwrites.
    Case(label: ".all + absent → records, fails once", mode: .all, precondition: .absent, expectedFailures: 1, expectedAfter: .canonical),
    Case(label: ".all + matching → re-records anyway, fails", mode: .all, precondition: .matching, expectedFailures: 1, expectedAfter: .canonical),
    Case(label: ".all + mismatching → overwrites, fails", mode: .all, precondition: .mismatching, expectedFailures: 1, expectedAfter: .canonical),

    // .failed — writes only when the comparison fails (missing counts as failing), so a match
    // passes untouched and a mismatch is overwritten.
    Case(label: ".failed + absent → records, fails once", mode: .failed, precondition: .absent, expectedFailures: 1, expectedAfter: .canonical),
    Case(label: ".failed + matching → passes, unchanged", mode: .failed, precondition: .matching, expectedFailures: 0, expectedAfter: .canonical),
    Case(label: ".failed + mismatching → overwrites, fails", mode: .failed, precondition: .mismatching, expectedFailures: 1, expectedAfter: .canonical),
  ])
  func recordModeMatrix(_ testCase: Case) throws {
    let directory = try Self.scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let canonical = try Self.canonicalReferenceContent()

    switch testCase.precondition {
    case .absent:
      break
    case .matching:
      try Self.writeReference(canonical, in: directory)
    case .mismatching:
      try Self.writeReference(Self.mismatchingContent, in: directory)
    }

    let failures = Self.runAssertion(content: Self.content, directory: directory, record: testCase.mode)

    #expect(failures == testCase.expectedFailures, "\(testCase.label): failure count")

    let after = try Self.referenceContent(in: directory)
    switch testCase.expectedAfter {
    case .absent:
      #expect(after == nil, "\(testCase.label): reference should not exist")
    case .canonical:
      #expect(after == canonical, "\(testCase.label): reference should be the render's content")
    case .mismatching:
      #expect(after == Self.mismatchingContent, "\(testCase.label): reference should be left untouched")
    }
  }

  // MARK: - Harness

  /// Runs one assertion with the given record mode and returns how many failures it reported.
  private static func runAssertion(
    content: String,
    directory: URL,
    record: RecordSnapshotTrait.RecordKind
  ) -> Int {
    RecordSnapshotTrait.$current.withValue(record) {
      Asserter().collectFailuresSync(from: [makeRequest(content: content, directory: directory)])
    }
    .count
  }

  /// The exact bytes pointfree records for `content`, captured by recording once into a
  /// throwaway directory rather than assuming the text strategy's serialization.
  private static func canonicalReferenceContent() throws -> String {
    let directory = try scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    _ = runAssertion(content: content, directory: directory, record: .missing)

    return try #require(try referenceContent(in: directory))
  }

  private static func makeRequest(content: String, directory: URL) -> AssertionRequest<String> {
    AssertionRequest(
      view: SnapshotViewController(),
      snapshotting: Snapshotting<String, String>.lines.pullback { (_: SnapshotViewController) in content },
      snapshotDirectory: directory.path,
      testName: "sharedName",
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )
  }

  private static func writeReference(_ content: String, in directory: URL) throws {
    try content.write(
      to: directory.appendingPathComponent(referenceFileName),
      atomically: true,
      encoding: .utf8
    )
  }

  private static func referenceContent(in directory: URL) throws -> String? {
    let url = directory.appendingPathComponent(referenceFileName)
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    return try String(contentsOf: url, encoding: .utf8)
  }

  private static func scratchDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapshotRecordModeTests", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
#endif
