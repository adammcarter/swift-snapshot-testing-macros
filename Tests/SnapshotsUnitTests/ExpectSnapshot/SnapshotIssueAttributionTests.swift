import Foundation
import SnapshotTestingMacros
import SwiftUI
import Testing

/// Regression coverage for issue attribution across the adapter's main-actor hop.
///
/// `#expectSnapshot` called off the main thread crosses to the main actor to render and
/// verify. Failures raised on the far side of that hop must be recorded back on the *test's*
/// task — where `Test.current` is intact — so the issue fails the invoking test and
/// `withKnownIssue` can match it. They used to be recorded inside a `DispatchQueue.main.sync`
/// callout, where Swift Testing's task-locals are gone: the failure surfaced as an orphaned
/// run-level issue, the failing test itself reported as passing, and `withKnownIssue`
/// produced a spurious "issue was not recorded" failure.
///
/// The async overloads additionally must hop structurally (staying on the test's task) rather
/// than parking a cooperative-pool thread inside `DispatchQueue.main.sync`; the render probes
/// below prove the structured bridge by observing `Test.current` *inside* the main-actor
/// render, which a GCD callout cannot preserve.
struct SnapshotIssueAttributionTests {
  /// The reference is deliberately missing and recording is disabled, so the assertion must
  /// fail — and that failure must be attributed to this (non-`@MainActor`) test: the
  /// surrounding `withKnownIssue` only matches issues recorded on the test's own task.
  @Test(.record(.never), .theme(.light))
  func failureFromNonMainThreadSyncOverloadIsAttributedToTheTest() throws {
    try #require(!Thread.isMainThread)

    withKnownIssue {
      #expectSnapshot(Color.blue.frame(width: 4, height: 4), named: "attributionProbe")
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
    }
  }

  /// The async overload must bridge to the main actor structurally (`await`, same task), not
  /// via `DispatchQueue.main.sync`: the view's body — evaluated during the main-actor render —
  /// must still see the test's task-locals, and the failure must match the known issue.
  @Test(.record(.never), .theme(.light))
  func asyncOverloadRendersOnTheTestTaskMainActorBridge() async throws {
    try #require(!currentThreadIsMain())
    let probe = RenderProbe()

    await withKnownIssue {
      await #expectSnapshot(named: "asyncBridgeProbe") {
        await Task.yield()
        return TaskLocalRenderProbeView(probe: probe)
      }
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
    }

    #expect(probe.sawTestTaskLocal == true)
    #expect(probe.sawMainThread == true)
  }

  /// Same contract for the configuration-based async overload (the `runLazyAsyncThrowing`
  /// path): structured main-actor bridge plus attributed failure.
  @Test(.record(.never), .theme(.light))
  func asyncConfigurationOverloadRendersOnTheTestTaskMainActorBridge() async throws {
    try #require(!currentThreadIsMain())
    let probe = RenderProbe()
    let configuration = SnapshotConfiguration(name: "probe", value: 1)

    await withKnownIssue {
      await #expectSnapshot(configuration, named: "asyncConfigurationBridgeProbe") { (_: Int) in
        await Task.yield()
        return TaskLocalRenderProbeView(probe: probe)
      }
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
    }

    #expect(probe.sawTestTaskLocal == true)
    #expect(probe.sawMainThread == true)
  }
}

/// `Thread.isMainThread` is unavailable directly in async contexts; the async tests above
/// only need it as a sanity gate that they are exercising the off-main path.
private func currentThreadIsMain() -> Bool {
  Thread.isMainThread
}

/// Records what the render observed; written from the view's body on the main actor and read
/// back on the test task after the assertion returns.
private final class RenderProbe: @unchecked Sendable {
  private let lock = NSLock()
  private var _sawTestTaskLocal: Bool?
  private var _sawMainThread: Bool?

  var sawTestTaskLocal: Bool? { lock.withLock { _sawTestTaskLocal } }
  var sawMainThread: Bool? { lock.withLock { _sawMainThread } }

  func record(sawTestTaskLocal: Bool, sawMainThread: Bool) {
    lock.withLock {
      _sawTestTaskLocal = sawTestTaskLocal
      _sawMainThread = sawMainThread
    }
  }
}

/// Observes, from inside the main-actor render, whether the test's task-locals survived the
/// hop: `Test.current` is only visible when the bridge stayed on the test's task.
private struct TaskLocalRenderProbeView: View {
  let probe: RenderProbe

  var body: some View {
    probe.record(
      sawTestTaskLocal: Test.current != nil,
      sawMainThread: Thread.isMainThread
    )
    return Color.red.frame(width: 4, height: 4)
  }
}
