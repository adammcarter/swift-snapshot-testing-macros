import Foundation
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Covers the `.N` reference-file identifier that pointfree appends to every reference name.
///
/// The native `#expectSnapshot` path must derive that identifier from the attempt-scoped
/// execution context — the per-attempt equivalent of pointfree's `.snapshots` trait binding a
/// fresh counter per test — so reference names are deterministic: every attempt (retry or
/// repetition) resolves the same `.1` name again, and two assertions within one attempt count
/// up deterministically instead of depending on process-global execution order.
@MainActor
struct ReferenceIdentifierAttemptScopingTests {
  /// A repetition or retry of a test is a new attempt: the same-named assertion must resolve
  /// the identical `.1` reference file recorded by the first attempt instead of drifting to
  /// `.2` and recording a stray new reference.
  @Test
  func sameNamedAssertionResolvesTheSameReferenceFileOnEveryAttempt() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    // First attempt: no reference exists yet, so record-missing writes it and records a
    // "recorded new snapshot" issue.
    try await trait.provideScope(for: test, testCase: Test.Case.current) { @MainActor in
      Self.assertOnAttemptContext(
        content: "stable content",
        directory: directory,
        expectingRecordedReference: true
      )
    }

    // Second attempt: the identifier must reset to `.1`, find the recorded reference, and
    // match without recording any issue.
    try await trait.provideScope(for: test, testCase: Test.Case.current) { @MainActor in
      Self.assertOnAttemptContext(
        content: "stable content",
        directory: directory,
        expectingRecordedReference: false
      )
    }

    #expect(try Self.referenceFileNames(in: directory) == ["sharedName.1.txt"])
  }

  /// Two same-named assertions within one attempt share the attempt's context, so their
  /// reference identifiers count up deterministically (`.1`, `.2`) in assertion order — and a
  /// fresh attempt maps the same assertions back onto the same files.
  @Test
  func twoAssertionsInOneAttemptKeepDeterministicDistinctReferenceFiles() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    try await trait.provideScope(for: test, testCase: Test.Case.current) { @MainActor in
      Self.assertOnAttemptContext(
        content: "first assertion content",
        directory: directory,
        expectingRecordedReference: true
      )
      Self.assertOnAttemptContext(
        content: "second assertion content",
        directory: directory,
        expectingRecordedReference: true
      )
    }

    // A new attempt in the same order must land on the recorded `.1`/`.2` pair — no drifting
    // to `.3`/`.4`, no order-dependent shuffling.
    try await trait.provideScope(for: test, testCase: Test.Case.current) { @MainActor in
      Self.assertOnAttemptContext(
        content: "first assertion content",
        directory: directory,
        expectingRecordedReference: false
      )
      Self.assertOnAttemptContext(
        content: "second assertion content",
        directory: directory,
        expectingRecordedReference: false
      )
    }

    #expect(try Self.referenceFileNames(in: directory) == ["sharedName.1.txt", "sharedName.2.txt"])
    #expect(try Self.referenceContent(in: directory, fileName: "sharedName.1.txt") == "first assertion content")
    #expect(try Self.referenceContent(in: directory, fileName: "sharedName.2.txt") == "second assertion content")
  }

  /// The context-level primitive behind the file behaviour above: identifiers count per key
  /// within one context and restart at `1` on a fresh context (a fresh attempt).
  @Test
  func referenceIdentifiersCountPerKeyWithinAContextAndResetWithAFreshContext() {
    let context = SnapshotExecutionContext(function: "probe()")

    #expect(context.nextReferenceIdentifier(forKey: "dir/sharedName") == "1")
    #expect(context.nextReferenceIdentifier(forKey: "dir/sharedName") == "2")
    #expect(context.nextReferenceIdentifier(forKey: "dir/otherName") == "1")

    let freshAttemptContext = SnapshotExecutionContext(function: "probe()")
    #expect(freshAttemptContext.nextReferenceIdentifier(forKey: "dir/sharedName") == "1")
  }

  /// Mirrors one `#expectSnapshot` call: resolve the attempt's execution context (via the
  /// task-local bound by the attempt token) and run one assertion request through the real
  /// `Asserter`, writing to and verifying against `directory`.
  @MainActor
  private static func assertOnAttemptContext(
    content: String,
    directory: URL,
    expectingRecordedReference: Bool
  ) {
    TaskLocalSnapshotExecutionContext.withCurrent(function: "attempt()") { _ in
      let requests: [any AssertionRequesting] = [
        makeRequest(content: content, directory: directory)
      ]

      if expectingRecordedReference {
        withKnownIssue {
          Asserter().assertSnapshotsSync(from: requests)
        }
      }
      else {
        Asserter().assertSnapshotsSync(from: requests)
      }
    }
  }

  @MainActor
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

  private static func makeScratchDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("ReferenceIdentifierAttemptScopingTests", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private static func referenceFileNames(in directory: URL) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
  }

  private static func referenceContent(in directory: URL, fileName: String) throws -> String {
    try String(contentsOf: directory.appendingPathComponent(fileName), encoding: .utf8)
  }
}
