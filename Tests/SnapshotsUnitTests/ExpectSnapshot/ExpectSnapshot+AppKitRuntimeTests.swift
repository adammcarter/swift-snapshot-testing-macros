#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

private enum AppKitSnapshotFailure: Error {
  case sentinel
}

struct ExpectSnapshotAppKitRuntimeTests {
  @Test
  func nsView() {
    #expectSnapshot(makeLabel("AppKit direct value"))
  }

  @Test
  func nsViewController() {
    #expectSnapshot(makeController(labeled: "AppKit controller direct value"))
  }

  @Test
  func throwingDirectNSViewRethrows() {
    do {
      try #expectSnapshot(try throwingView(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch AppKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingDirectNSViewControllerRethrows() {
    do {
      try #expectSnapshot(try throwingViewController(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch AppKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingConfigurationNSViewRethrows() {
    let configuration = SnapshotConfiguration(name: nil, value: "guest")

    do {
      try #expectSnapshot(configuration, named: "unused") { (_: String) throws -> NSView in
        throw AppKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch AppKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingNSViewBuilderRethrows() async {
    do {
      try await #expectSnapshot(named: "unused") { @MainActor () async throws -> NSView in
        await Task.yield()
        throw AppKitSnapshotFailure.sentinel
      }
      Issue.record("Expected sentinel error")
    }
    catch AppKitSnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test(.record(.never), .theme(.light))
  func asyncNSViewBuilderExecutesPipelineOnMainActorWithTestContext() async throws {
    try #require(!currentThreadIsMain())
    let probe = AppKitAsyncRenderProbe()
    let assertionLine = #line + 3

    await withKnownIssue {
      await #expectSnapshot(named: "asyncAppKitBuilderProbe") { @MainActor () async -> NSView in
        await Task.yield()
        probe.recordBuilder(
          sawTestContext: Test.current != nil,
          sawMainThread: currentThreadIsMain()
        )
        return AppKitAsyncProbeView(probe: probe)
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
  func asyncThrowingNSViewBuilderExecutesPipelineOnMainActorWithTestContext() async throws {
    try #require(!currentThreadIsMain())
    let probe = AppKitAsyncRenderProbe()
    let assertionLine = #line + 4

    await withKnownIssue {
      do {
        try await #expectSnapshot(named: "asyncThrowingAppKitBuilderProbe") {
          @MainActor () async throws -> NSView in
          await Task.yield()
          probe.recordBuilder(
            sawTestContext: Test.current != nil,
            sawMainThread: currentThreadIsMain()
          )
          return AppKitAsyncProbeView(probe: probe)
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

  @Test(
    .theme(.light),
    .sizes(width: 160, height: 80),
    .backgroundColor(.red),
    .padding(8)
  )
  func decoratedNSViewUsesFixedSize() {
    #expectSnapshot(makeLabel("AppKit decorated fixed size"), named: "appkit-decorated-fixed")
  }

  /// Mirrors the body shape the migration rewriter emits for legacy
  /// `configurationValues:` tests on AppKit/UIKit platforms; artifacts land in the legacy
  /// layout `<display>/<case>_<display>_<size>_<theme>`.
  ///
  /// Plain views keep the recursive-description artifacts free of private AppKit class
  /// names, so the recorded references stay stable across OS versions.
  @MainActor
  @Test(.strategy(.recursiveDescription), .theme(.light), arguments: [1, 2])
  func migratedParameterizedController(value: Int) {
    let snapshotConfiguration = SnapshotConfiguration(name: "\(value)", value: value)
    let snapshotValue: NSViewController = makePlainController(width: 200, height: 100)
    #expectSnapshot(snapshotConfiguration, named: "Migrated parameterized controller") { _ in snapshotValue }
  }

  /// Mirrors the body shape the migration rewriter emits for legacy `configurations:`
  /// tests on AppKit/UIKit platforms.
  @MainActor
  @Test(
    .strategy(.recursiveDescription),
    .theme(.light),
    arguments: [SnapshotConfiguration(name: "compact", value: 120.0)]
  )
  func migratedParameterizedView(configuration: SnapshotConfiguration<Double>) {
    let snapshotConfiguration = configuration
    let width = configuration.value
    let snapshotValue: NSView = makePlainView(width: width, height: 80)
    #expectSnapshot(snapshotConfiguration, named: "Migrated parameterized view") { _ in snapshotValue }
  }
}

@MainActor
private func makeLabel(_ string: String) -> NSTextField {
  let label = NSTextField(labelWithString: string)
  label.sizeToFit()
  return label
}

@MainActor
private func makeController(labeled string: String) -> NSViewController {
  let controller = NSViewController()
  controller.view = makeLabel(string)
  return controller
}

@MainActor
private func throwingView() throws -> NSView {
  throw AppKitSnapshotFailure.sentinel
}

@MainActor
private func throwingViewController() throws -> NSViewController {
  throw AppKitSnapshotFailure.sentinel
}

@MainActor
private func makePlainView(width: Double, height: Double) -> NSView {
  let view = NSView(frame: .init(x: 0, y: 0, width: width, height: height))
  view.widthAnchor.constraint(equalToConstant: width).isActive = true
  view.heightAnchor.constraint(equalToConstant: height).isActive = true
  return view
}

@MainActor
private func makePlainController(width: Double, height: Double) -> NSViewController {
  let controller = NSViewController()
  controller.view = makePlainView(width: width, height: height)
  return controller
}

private func currentThreadIsMain() -> Bool {
  Thread.isMainThread
}

private final class AppKitAsyncRenderProbe: @unchecked Sendable {
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
private final class AppKitAsyncProbeView: NSView {
  private let probe: AppKitAsyncRenderProbe

  init(probe: AppKitAsyncRenderProbe) {
    self.probe = probe
    super.init(frame: .init(x: 0, y: 0, width: 160, height: 80))
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("AppKitAsyncProbeView does not support init(coder:)")
  }

  override func layout() {
    super.layout()
    probe.recordRender(
      sawTestContext: Test.current != nil,
      sawMainThread: Thread.isMainThread
    )
  }
}
#endif
