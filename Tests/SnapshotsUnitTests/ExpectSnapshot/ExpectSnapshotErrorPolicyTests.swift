import Foundation
import SwiftUI
import Testing

@testable import SnapshotTestingMacros

/// Characterization coverage for the funnel's error policy: which `#expectSnapshot` overloads
/// record pipeline errors as issues and which rethrow them to the caller.
///
/// "Pipeline errors" are errors raised by the assertion pipeline itself — here provoked
/// deterministically with an invalid `.sizes` trait, which makes request generation throw
/// inside the main-actor hop — as opposed to errors thrown by the user's `makeValue` closure
/// (covered by the rethrow tests in `ExpectSnapshotAdapterTests`) and snapshot verification
/// failures (always recorded, covered by `SnapshotIssueAttributionTests`).
///
/// The contract these tests pin down:
/// - Non-throwing overloads (sync and async) record pipeline errors on the invoking test.
/// - Throwing overloads rethrow pipeline errors — with one historical exception: the
///   no-configuration sync throwing overload only rethrows errors from its `makeValue`
///   closure (evaluated eagerly on the caller's thread) and records pipeline errors like its
///   non-throwing sibling.
/// - The no-configuration sync closure runs on the caller's thread before the main-actor
///   hop; configuration-based sync closures run on the main actor inside the hop.
extension ExpectSnapshotAdapterTests {
  private static let invalidWidthMessageFragment = "Invalid fixed width"

  private static func isInvalidWidthIssue(_ issue: Issue) -> Bool {
    issue.error?.localizedDescription.contains(invalidWidthMessageFragment) == true
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func syncValueOverloadRecordsPipelineErrors() {
    withKnownIssue {
      #expectSnapshot(Text("pipeline"), named: "unused")
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func syncClosureOverloadRecordsPipelineErrorsAndEvaluatesMakeValueOnTheCallersThread() throws {
    try #require(!Thread.isMainThread)
    var sawMainThread: Bool?

    withKnownIssue {
      __expectSnapshot(named: "unused") { () -> Text in
        sawMainThread = Thread.isMainThread
        return Text("pipeline")
      }
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }

    #expect(sawMainThread == false)
  }

  /// The sync throwing overload's historical hybrid: `makeValue` errors rethrow (see
  /// `throwingClosureHelperRethrowsClosureErrors`), but pipeline errors are recorded — the
  /// call returns normally.
  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func syncThrowingClosureOverloadRecordsPipelineErrorsInsteadOfRethrowing() {
    withKnownIssue {
      do {
        try __expectSnapshot(named: "unused") { () throws -> Text in
          Text("pipeline")
        }
      }
      catch {
        Issue.record("Expected the pipeline error to be recorded, not rethrown; threw: \(error)")
      }
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func asyncClosureOverloadRecordsPipelineErrors() async {
    await withKnownIssue {
      await __expectSnapshot(named: "unused") { () async -> Text in
        await Task.yield()
        return Text("pipeline")
      }
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func asyncThrowingClosureOverloadRethrowsPipelineErrors() async {
    do {
      try await __expectSnapshot(named: "unused") { () async throws -> Text in
        await Task.yield()
        return Text("pipeline")
      }

      Issue.record("Expected the pipeline error to be rethrown")
    }
    catch {
      #expect(error.localizedDescription.contains(Self.invalidWidthMessageFragment))
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func syncConfigurationOverloadRecordsPipelineErrorsAndEvaluatesMakeValueOnTheMainActor() throws {
    try #require(!Thread.isMainThread)
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")
    var sawMainThread: Bool?

    withKnownIssue {
      #expectSnapshot(configuration, named: "unused") { (_: String) -> Text in
        sawMainThread = Thread.isMainThread
        return Text("pipeline")
      }
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }

    #expect(sawMainThread == true)
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func syncThrowingConfigurationOverloadRethrowsPipelineErrors() {
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String) throws -> Text in
        Text("pipeline")
      }

      Issue.record("Expected the pipeline error to be rethrown")
    }
    catch {
      #expect(error.localizedDescription.contains(Self.invalidWidthMessageFragment))
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func asyncConfigurationOverloadRecordsPipelineErrors() async {
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")

    await withKnownIssue {
      await #expectSnapshot(configuration, named: "unused") { (_: String) async -> Text in
        await Task.yield()
        return Text("pipeline")
      }
    } matching: { issue in
      Self.isInvalidWidthIssue(issue)
    }
  }

  @Test(.sizes(width: .fixed(-1), height: .fixed(10)), .record(.never))
  func asyncThrowingConfigurationOverloadRethrowsPipelineErrors() async {
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")

    do {
      try await #expectSnapshot(configuration, named: "unused") { (_: String) async throws -> Text in
        await Task.yield()
        return Text("pipeline")
      }

      Issue.record("Expected the pipeline error to be rethrown")
    }
    catch {
      #expect(error.localizedDescription.contains(Self.invalidWidthMessageFragment))
    }
  }
}
