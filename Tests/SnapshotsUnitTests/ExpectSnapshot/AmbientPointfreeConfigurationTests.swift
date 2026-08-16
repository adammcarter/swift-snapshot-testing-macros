import Foundation
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Covers how the asserter resolves `record`/`diffTool` when no package trait is set.
///
/// The asserter must not clobber ambient pointfree-native configuration — a consumer's own
/// `withSnapshotTesting(record:diffTool:)`, pointfree's `.snapshots` trait, or the
/// `SNAPSHOT_TESTING_RECORD` environment variable. Package traits are task-local *overrides*:
/// unset traits stay `nil` and fall through to whatever pointfree configuration is ambient,
/// which itself falls back to pointfree's defaults.
@MainActor
struct AmbientPointfreeConfigurationTests {
  private final class NonSendableResult {
    let record: RecordSnapshotTrait.RecordKind?

    init(record: RecordSnapshotTrait.RecordKind?) {
      self.record = record
    }
  }

  /// A consumer-level `withSnapshotTesting(record: .never)` around a native assertion must be
  /// honoured when no `.record` trait is set: the missing reference is NOT recorded.
  ///
  /// Regression: the asserter used to wrap every assertion in
  /// `withSnapshotTesting(record: .missing, ...)` built from non-optional trait defaults,
  /// which overrode the ambient `.never` and silently wrote the reference anyway.
  @Test
  func ambientRecordConfigurationIsHonouredWhenNoTraitIsSet() throws {
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let failures = withSnapshotTesting(record: .never) {
      Asserter().collectFailuresSync(from: [Self.makeRequest(content: "content", directory: directory)])
    }

    #expect(failures.count == 1)
    #expect(try Self.referenceFileNames(in: directory).isEmpty)
  }

  /// The `.record` trait must still win over ambient pointfree configuration when both are
  /// present: trait `.missing` records the reference even under ambient `.never`.
  @Test
  func recordTraitWinsOverAmbientConfiguration() throws {
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let failures = withSnapshotTesting(record: .never) {
      RecordSnapshotTrait.$current.withValue(.missing) {
        Asserter().collectFailuresSync(from: [Self.makeRequest(content: "content", directory: directory)])
      }
    }

    // Recording a missing reference still reports one "recorded new snapshot" failure.
    #expect(failures.count == 1)
    #expect(try Self.referenceFileNames(in: directory) == ["sharedName.1.txt"])
  }

  /// A consumer-level ambient diff tool must be honoured when no `.diffTool` trait is set:
  /// mismatch failure messages are built with the ambient tool, not the clobbered default.
  @Test
  func ambientDiffToolConfigurationIsHonouredWhenNoTraitIsSet() throws {
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    try "recorded content"
      .write(
        to: directory.appendingPathComponent("sharedName.1.txt"),
        atomically: true,
        encoding: .utf8
      )

    let marker = "AMBIENT_DIFF_TOOL_MARKER"
    let failures = withSnapshotTesting(diffTool: .init { _, _ in marker }) {
      Asserter().collectFailuresSync(from: [Self.makeRequest(content: "mismatching content", directory: directory)])
    }

    #expect(failures.count == 1)
    #expect(failures.first?.message?.contains(marker) == true)
  }

  /// The runtime state captured on the test's task must carry the ambient pointfree
  /// configuration across the adapter's main-queue hop, where task-locals do not flow:
  /// applying the captured state outside the ambient scope must still honour `.never`.
  @Test
  func capturedRuntimeStateCarriesAmbientConfigurationAcrossTheMainQueueHop() throws {
    let directory = try Self.makeScratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    // Capture on the test's task, inside the consumer's ambient scope — as the adapter does
    // before hopping to the main queue.
    let runtimeState = withSnapshotTesting(record: .never) {
      ResolvedSnapshotRuntimeState.current
    }

    // Apply outside the ambient scope — as on the far side of `DispatchQueue.main.sync`,
    // where the consumer's task-local binding is gone.
    let failures = runtimeState.withAppliedValues {
      Asserter().collectFailuresSync(from: [Self.makeRequest(content: "content", directory: directory)])
    }

    #expect(failures.count == 1)
    #expect(try Self.referenceFileNames(in: directory).isEmpty)
  }

  @Test
  func capturedRuntimeStateCarriesTraitConfigurationAcrossAsyncOperation() async {
    let runtimeState = RecordSnapshotTrait.$current.withValue(.never) {
      ResolvedSnapshotRuntimeState.current
    }

    let result = await runtimeState.withAppliedValues {
      await Task.yield()
      return NonSendableResult(record: RecordSnapshotTrait.current)
    }

    #expect(result.record == .never)
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
      .appendingPathComponent("AmbientPointfreeConfigurationTests", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private static func referenceFileNames(in directory: URL) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
  }
}
