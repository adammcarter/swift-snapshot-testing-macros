#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

private enum UIKitSnapshotFailure: Error {
  case sentinel
}

struct ExpectSnapshotUIKitTests {
  @Test
  func uiView() {
    #expectSnapshot(makeLabel("UIKit direct value"), named: "uiView")
  }

  @Test
  func uiViewController() {
    #expectSnapshot(
      makeController(labeled: "UIKit controller direct value"),
      named: "uiViewController"
    )
  }

  @Test
  func throwingDirectUIViewRethrows() {
    do {
      try #expectSnapshot(try throwingUIView(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingDirectUIViewControllerRethrows() {
    do {
      try #expectSnapshot(try throwingUIViewController(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingArgumentUIViewBuilderRethrows() {
    do {
      try #expectSnapshot(argument: "guest", named: "unused") { (_: String) throws -> UIView in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingArgumentUIViewControllerBuilderRethrows() {
    do {
      try #expectSnapshot(argument: "guest", named: "unused") { (_: String) throws -> UIViewController in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingConfigurationUIViewBuilderRethrows() {
    let configuration = SnapshotConfiguration(name: nil, value: "guest")

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String) throws -> UIView in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingConfigurationUIViewControllerBuilderRethrows() {
    let configuration = SnapshotConfiguration(name: nil, value: "guest")

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String) throws -> UIViewController in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingTuple2ConfigurationUIViewBuilderRethrows() {
    let configuration = SnapshotConfiguration(name: nil, value: ("guest", 1))

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String, _: Int) throws -> UIView in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingTuple3ConfigurationUIViewControllerBuilderRethrows() {
    let configuration = SnapshotConfiguration(name: nil, value: ("guest", 1, true))

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String, _: Int, _: Bool) throws -> UIViewController in
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingUIViewBuilderRethrows() async {
    do {
      try await #expectSnapshot(named: "unused") { () async throws -> UIView in
        await Task.yield()
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingUIViewControllerBuilderRethrows() async {
    do {
      try await #expectSnapshot(named: "unused") { () async throws -> UIViewController in
        await Task.yield()
        throw UIKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch UIKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test(.record(.never), .theme(.light))
  func asyncArgumentUIViewBuilderExecutesPipelineOnMainActorWithTestContext() async throws {
    try #require(!currentThreadIsMain())
    let probe = UIKitAsyncRenderProbe()
    let assertionLine = #line + 3

    await withKnownIssue {
      await #expectSnapshot(argument: "guest", named: "asyncUIKitArgumentProbe") { @MainActor (_: String) async -> UIView in
        await Task.yield()
        probe.recordBuilder(
          sawTestContext: Test.current != nil,
          sawMainThread: currentThreadIsMain()
        )
        return UIKitAsyncProbeView(probe: probe)
      }
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
        && issue.sourceLocation?.fileID == #fileID.description
        && issue.sourceLocation?.line == assertionLine
    }

    #expect(probe.builderSawTestContext == true)
    #expect(probe.builderSawMainThread == true)
    #expect(probe.renderSawTestContext == true)
    #expect(probe.renderSawMainThread == true)
  }

  @Test(.record(.never), .theme(.light))
  func asyncThrowingConfigurationUIViewBuilderExecutesPipelineOnMainActorWithTestContext() async throws {
    try #require(!currentThreadIsMain())
    let probe = UIKitAsyncRenderProbe()
    let configuration = SnapshotConfiguration(name: nil, value: "guest")
    let assertionLine = #line + 4

    await withKnownIssue {
      do {
        try await #expectSnapshot(configuration, named: "asyncThrowingUIKitConfigurationProbe") { @MainActor (_: String) async throws -> UIView in
          await Task.yield()
          probe.recordBuilder(
            sawTestContext: Test.current != nil,
            sawMainThread: currentThreadIsMain()
          )
          return UIKitAsyncProbeView(probe: probe)
        }
      }
      catch {
        Issue.record("Expected the async throwing builder to complete, got: \(error)")
      }
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
        && issue.sourceLocation?.fileID == #fileID.description
        && issue.sourceLocation?.line == assertionLine
    }

    #expect(probe.builderSawTestContext == true)
    #expect(probe.builderSawMainThread == true)
    #expect(probe.renderSawTestContext == true)
    #expect(probe.renderSawMainThread == true)
  }
}

@MainActor
private func throwingUIView() throws -> UIView {
  throw UIKitSnapshotFailure.sentinel
}

@MainActor
private func throwingUIViewController() throws -> UIViewController {
  throw UIKitSnapshotFailure.sentinel
}

private func currentThreadIsMain() -> Bool {
  Thread.isMainThread
}

private final class UIKitAsyncRenderProbe: @unchecked Sendable {
  private let lock = NSLock()
  private var _builderSawTestContext = false
  private var _builderSawMainThread = false
  private var _renderSawTestContext = false
  private var _renderSawMainThread = false

  var builderSawTestContext: Bool { lock.withLock { _builderSawTestContext } }
  var builderSawMainThread: Bool { lock.withLock { _builderSawMainThread } }
  var renderSawTestContext: Bool { lock.withLock { _renderSawTestContext } }
  var renderSawMainThread: Bool { lock.withLock { _renderSawMainThread } }

  func recordBuilder(sawTestContext: Bool, sawMainThread: Bool) {
    lock.withLock {
      _builderSawTestContext = sawTestContext
      _builderSawMainThread = sawMainThread
    }
  }

  func recordRender(sawTestContext: Bool, sawMainThread: Bool) {
    lock.withLock {
      _renderSawTestContext = sawTestContext
      _renderSawMainThread = sawMainThread
    }
  }
}

@MainActor
private final class UIKitAsyncProbeView: UIView {
  private let probe: UIKitAsyncRenderProbe

  init(probe: UIKitAsyncRenderProbe) {
    self.probe = probe
    super.init(frame: .init(x: 0, y: 0, width: 160, height: 80))
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("UIKitAsyncProbeView does not support init(coder:)")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    probe.recordRender(
      sawTestContext: Test.current != nil,
      sawMainThread: Thread.isMainThread
    )
  }
}
#endif
