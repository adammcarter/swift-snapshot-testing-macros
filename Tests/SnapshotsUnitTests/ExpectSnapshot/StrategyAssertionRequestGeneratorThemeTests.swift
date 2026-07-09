#if canImport(AppKit)
import AppKit
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Regression tests for the AppKit theme fan-out: the theme trait produces `_light`/`_dark`
/// artifacts, so the rendered pixels must actually differ between the two appearances.
@MainActor
struct StrategyAssertionRequestGeneratorThemeTests {
  @Test
  func lightAndDarkThemesRenderDifferentImageData() throws {
    let lightData = try renderedImageData(request: makeImageRequest(theme: .light))
    let darkData = try renderedImageData(request: makeImageRequest(theme: .dark))

    #expect(lightData != darkData)
  }

  /// The snapshot value can be a single cached instance shared by every request in the theme
  /// fan-out (`#expectSnapshot(myView)` evaluates its autoclosure once), and the runner generates
  /// every request before rendering any of them. The theme's appearance therefore must be applied
  /// at render time; applying it when the request is generated lets the last-generated theme win
  /// for every artifact.
  @Test
  func sharedSnapshotViewAcrossThemeFanOutRendersDifferentImageData() throws {
    let sharedViewController = SnapshotViewController()
    sharedViewController.view = DynamicBackgroundView(
      frame: NSRect(x: 0, y: 0, width: 32, height: 32)
    )

    let context = makeContext { sharedViewController }

    // Generate all requests before rendering any, mirroring the assertion pipeline.
    let lightRequest = try makeImageRequest(theme: .light, context: context)
    let darkRequest = try makeImageRequest(theme: .dark, context: context)

    let lightData = try renderedImageData(request: lightRequest)
    let darkData = try renderedImageData(request: darkRequest)

    #expect(lightData != darkData)
  }

  /// Renders through the exact `Snapshotting` strategy and diffing pipeline the assertion runner
  /// uses, returning the artifact bytes that would be written to disk.
  private func renderedImageData(request: AssertionRequest<NSImage>) throws -> Data {
    var renderedImage: NSImage?
    request.snapshotting.snapshot(request.view).run { renderedImage = $0 }

    let image = try #require(renderedImage)
    return request.snapshotting.diffing.toData(image)
  }

  private func makeImageRequest(
    theme: SnapshotTheme,
    context: AssertionRequestContext? = nil
  ) throws -> AssertionRequest<NSImage> {
    let resolvedContext =
      context
      ?? makeContext {
        let viewController = SnapshotViewController()
        viewController.view = DynamicBackgroundView(
          frame: NSRect(x: 0, y: 0, width: 32, height: 32)
        )
        return viewController
      }

    let generator = StrategyAssertionRequestGenerator(
      context: resolvedContext,
      size: CGSize(width: 32, height: 32),
      theme: theme,
      displayScale: 1,
      testName: "themeProbe"
    )

    let requests = try generator.generateRequestsSync()
    return try #require(requests.first as? AssertionRequest<NSImage>)
  }

  private func makeContext(
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController
  ) -> AssertionRequestContext {
    AssertionRequestContext(
      name: "themeProbe",
      configurationName: nil,
      traitConfiguration: .init(
        sizes: [.init(width: .minimum, height: .minimum)],
        theme: .all,
        strategy: .image
      ),
      makeSnapshotView: makeSnapshotView,
      snapshotDirectory: NSTemporaryDirectory(),
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )
  }
}

/// Fills itself with a dynamic color that resolves differently under light and dark appearances.
private final class DynamicBackgroundView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    NSColor.windowBackgroundColor.setFill()
    dirtyRect.fill()
  }
}
#endif
