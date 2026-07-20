import SwiftUI
import Testing

@testable import SnapshotTestingMacros

/// Regression tests for the raw platform-view generator entry point.
///
/// `#expectSnapshot(UIView)` / `#expectSnapshot(NSView)` used to wrap the caller's view via
/// `controller.view = view`, marking the controller's view as loaded without ever running the
/// documented `loadView()`/`viewDidLoad()` sequence. The wrapper must instead defer to the
/// standard lifecycle so controller-side setup hooks keep firing.
@MainActor
@Suite
struct InjectedViewLifecycleTests {

  @Test
  func rawViewGeneratorLoadsTheInjectedViewThroughTheControllerLifecycle() throws {
    let view = SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
    let generator = SnapshotViewGenerator<Void>(
      displayName: "raw view",
      configuration: .none,
      makeValue: { _ in view },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    let controller = try generator.makeViewController(())

    #expect(!controller.isViewLoaded, "the view must load lazily through loadView(), not eager assignment")
    #expect(controller.view === view)
    #expect(controller.isViewLoaded)
  }

  @Test
  func asyncRawViewGeneratorLoadsTheInjectedViewThroughTheControllerLifecycle() async throws {
    let view = SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
    let generator = SnapshotViewGenerator<Void>(
      displayName: "async raw view",
      configuration: .none,
      makeValue: { _ in await Self.makeViewAsync(view) },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    let makeViewControllerAsync = try #require(generator.makeViewControllerAsync)
    let controller = try await makeViewControllerAsync(())

    #expect(!controller.isViewLoaded, "the view must load lazily through loadView(), not eager assignment")
    #expect(controller.view === view)
    #expect(controller.isViewLoaded)
  }

  @Test
  func injectedViewControllerRunsViewDidLoadExactlyOnceAfterLoadView() {
    let view = SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
    let controller = LifecycleProbeViewController(view: view)

    #expect(controller.viewDidLoadCallCount == 0)
    #expect(controller.view === view)
    #expect(controller.viewDidLoadCallCount == 1)

    _ = controller.view
    #expect(controller.viewDidLoadCallCount == 1)
  }

  private static func makeViewAsync(_ view: SnapshotView) async -> SnapshotView {
    view
  }
}

@MainActor
private final class LifecycleProbeViewController: SnapshotInjectedViewController {
  private(set) var viewDidLoadCallCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    viewDidLoadCallCount += 1
  }
}
