#if canImport(AppKit)
import AppKit
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Regression tests for the AppKit image render pass: the request's computed size must be laid
/// out for real (offscreen window hosting plus an Auto Layout pass, mirroring the UIKit path),
/// the request's display scale must decide the bitmap's pixel density deterministically, and the
/// `.backgroundColor` decorator must actually paint on macOS.
@MainActor
struct AppKitImageRenderingTests {
  /// An unspecified scale must render deterministically at one pixel per point. Inheriting the
  /// machine's `NSScreen` backing scale would make committed references differ between Retina
  /// and non-Retina machines running the same tests.
  @Test
  func unspecifiedScaleRendersOnePixelPerPoint() throws {
    let request = try makeThemeFanOutRequest(
      traitSize: .init(width: .fixed(100), height: .fixed(50)),
      size: CGSize(width: 100, height: 50)
    )

    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 100)
    #expect(bitmap.pixelsHigh == 50)
  }

  /// `.sizes(width:height:scale:)` documents an explicit scale factor; the AppKit render must
  /// honour it by scaling the bitmap's pixel density while keeping the point size.
  @Test
  func explicitScaleMultipliesRenderedPixelDimensions() throws {
    let request = try makeImageRequest(
      size: CGSize(width: 100, height: 50),
      displayScale: 3
    ) {
      makeFillController(fill: .srgbRed)
    }

    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 300)
    #expect(bitmap.pixelsHigh == 150)

    // The content must cover the full scaled bitmap, not render at 1x into a corner.
    try expectColor(in: bitmap, atX: 297, y: 147, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 150, y: 75, isApproximately: .srgbRed)
  }

  /// A fixed-size request must re-lay-out the hosted view at the request size before rendering:
  /// Auto Layout children must be solved against the requested bounds, not left at whatever
  /// frames a previous (or absent) layout pass produced.
  @Test
  func fixedSizeRequestLaysOutAutoLayoutContentAtRequestedSize() throws {
    let request = try makeImageRequest(
      size: CGSize(width: 200, height: 100),
      displayScale: 1
    ) {
      makeInsetChildController(rootFill: .srgbRed, childFill: .srgbBlue, inset: 10)
    }

    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 200)
    #expect(bitmap.pixelsHigh == 100)

    // 10pt border band shows the root; the child pinned inside the insets fills the middle.
    try expectColor(in: bitmap, atX: 4, y: 4, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 195, y: 95, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 100, y: 50, isApproximately: .srgbBlue)
  }

  /// The size fan-out shares one view controller across every request, so each render must
  /// re-host and re-lay-out that shared view at its own request size.
  @Test
  func multiSizeFanOutRendersEachRequestedSizeFromSharedView() throws {
    let sharedController = makeInsetChildController(rootFill: .srgbRed, childFill: .srgbBlue, inset: 10)

    // Generate all requests before rendering any, mirroring the assertion pipeline.
    let smallRequest = try makeImageRequest(
      size: CGSize(width: 120, height: 40),
      displayScale: 1
    ) { sharedController }
    let largeRequest = try makeImageRequest(
      size: CGSize(width: 240, height: 80),
      displayScale: 1
    ) { sharedController }

    let smallBitmap = try renderedBitmap(request: smallRequest)
    let largeBitmap = try renderedBitmap(request: largeRequest)

    #expect(smallBitmap.pixelsWide == 120)
    #expect(smallBitmap.pixelsHigh == 40)
    try expectColor(in: smallBitmap, atX: 2, y: 2, isApproximately: .srgbRed)
    try expectColor(in: smallBitmap, atX: 60, y: 20, isApproximately: .srgbBlue)

    #expect(largeBitmap.pixelsWide == 240)
    #expect(largeBitmap.pixelsHigh == 80)
    try expectColor(in: largeBitmap, atX: 236, y: 76, isApproximately: .srgbRed)
    try expectColor(in: largeBitmap, atX: 120, y: 40, isApproximately: .srgbBlue)
  }

  /// `.backgroundColor(...)` decorates snapshots by writing to the container view's
  /// `backgroundColor`; on macOS that write must actually paint (the container's backing layer
  /// only exists once the view is layer-backed).
  @Test
  func backgroundColorOnDecoratedContainerIsRendered() throws {
    let request = try makeImageRequest(
      size: CGSize(width: 64, height: 64),
      displayScale: 1
    ) {
      let payload = SnapshotViewController()
      payload.view = NSView()

      let insets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
      let container = payload.wrappingInContainerViewController(insets: insets)
      container.view.backgroundColor = .srgbRed
      return container
    }

    let bitmap = try renderedBitmap(request: request)

    try expectColor(in: bitmap, atX: 2, y: 2, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 61, y: 61, isApproximately: .srgbRed)
  }

  /// A dynamic decorator background color must resolve per theme at render time, matching the
  /// UIKit path where dynamic colors resolve against the render-time trait collection.
  @Test
  func dynamicDecoratorBackgroundColorResolvesPerTheme() throws {
    let configuration = __SnapshotViewDecoratorConfiguration(
      backgroundColor: .windowBackgroundColor,
      padding: nil
    )

    let (lightRequest, darkRequest) = try __SnapshotViewDecoratorConfiguration.$value.withValue(
      configuration
    ) {
      (
        try makeImageRequest(size: CGSize(width: 32, height: 32), displayScale: 1, theme: .light) {
          makeDecoratedContainer()
        },
        try makeImageRequest(size: CGSize(width: 32, height: 32), displayScale: 1, theme: .dark) {
          makeDecoratedContainer()
        }
      )
    }

    let lightBitmap = try renderedBitmap(request: lightRequest)
    let darkBitmap = try renderedBitmap(request: darkRequest)

    let lightCorner = try #require(color(in: lightBitmap, atX: 2, y: 2))
    let darkCorner = try #require(color(in: darkBitmap, atX: 2, y: 2))

    #expect(lightCorner.alphaComponent == 1)
    #expect(darkCorner.alphaComponent == 1)
    #expect(components(of: lightCorner) != components(of: darkCorner))
  }

  /// A huge-but-finite fixed size must fail recoverably, not crash the whole test process. A
  /// `.fixed(50000)`×`.fixed(50000)` request at scale 2 asks for a ~100000×100000 pixel bitmap
  /// (~40 GB), which `NSBitmapImageRep` cannot allocate. The render pass used to `fatalError` on
  /// that; the size must instead be rejected as a recoverable `SnapshotError` (which the adapter
  /// records as an issue) before any request that would crash is ever produced.
  @Test
  func hugeFixedSizeIsRejectedRecoverablyInsteadOfCrashing() throws {
    let generator = StrategyAssertionRequestGenerator(
      context: makeContext { makeFillController(fill: .srgbRed) },
      size: CGSize(width: 50000, height: 50000),
      theme: .light,
      displayScale: 2,
      testName: "hugeSizeProbe"
    )

    #expect(throws: SnapshotError.self) {
      try generator.generateRequestsSync()
    }
  }

  /// The render pass overrides the caller's `appearance` (to the theme) and forces its backing
  /// layer on (to paint the decorator background). Both must be restored afterward so a snapshot
  /// does not permanently mutate a view instance the caller may reuse in a real layout.
  @Test
  func renderRestoresCallerViewAppearanceAndLayerBacking() throws {
    let view = NSView()
    #expect(view.appearance == nil)
    #expect(view.wantsLayer == false)

    let controller = SnapshotViewController()
    controller.view = view

    let configuration = __SnapshotViewDecoratorConfiguration(
      backgroundColor: .srgbRed,
      padding: nil
    )
    let request = try __SnapshotViewDecoratorConfiguration.$value.withValue(configuration) {
      try makeImageRequest(size: CGSize(width: 32, height: 32), displayScale: 1, theme: .dark) {
        controller
      }
    }
    _ = try renderedBitmap(request: request)

    #expect(view.appearance == nil)
    #expect(view.wantsLayer == false)
  }

  // MARK: - Request construction

  private func makeImageRequest(
    size: CGSize,
    displayScale: Double,
    theme: SnapshotTheme = .light,
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController
  ) throws -> AssertionRequest<NSImage> {
    let generator = StrategyAssertionRequestGenerator(
      context: makeContext(makeSnapshotView: makeSnapshotView),
      size: size,
      theme: theme,
      displayScale: displayScale,
      testName: "renderProbe"
    )

    let requests = try generator.generateRequestsSync()
    return try #require(requests.first as? AssertionRequest<NSImage>)
  }

  /// Builds the request through `ThemeAssertionRequestGenerator` so the display scale is
  /// resolved exactly as the assertion pipeline resolves it for the given size trait.
  private func makeThemeFanOutRequest(
    traitSize: SizesSnapshotTrait.Size,
    size: CGSize
  ) throws -> AssertionRequest<NSImage> {
    let generator = ThemeAssertionRequestGenerator(
      context: makeContext {
        makeFillController(fill: .srgbRed)
      },
      traitSize: traitSize,
      size: size
    )

    let requests = try generator.generateRequestsSync()
    return try #require(requests.first as? AssertionRequest<NSImage>)
  }

  private func makeContext(
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController
  ) -> AssertionRequestContext {
    AssertionRequestContext(
      name: "renderProbe",
      configurationName: nil,
      traitConfiguration: .init(
        sizes: [.init(width: .minimum, height: .minimum)],
        theme: .light,
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

  // MARK: - Rendering and sampling

  /// Renders through the exact `Snapshotting` strategy the assertion runner uses.
  private func renderedBitmap(request: AssertionRequest<NSImage>) throws -> NSBitmapImageRep {
    var renderedImage: NSImage?
    request.snapshotting.snapshot(request.view).run { renderedImage = $0 }

    let image = try #require(renderedImage)
    let bitmap = image.representations.compactMap { $0 as? NSBitmapImageRep }.first
    return try #require(bitmap)
  }

  /// Samples the bitmap's raw component values. The renderer stores sRGB bytes, but
  /// `colorAt(x:y:)` reports them in a generic-RGB-tagged container regardless of the rep's
  /// actual tag, so the components are compared numerically rather than via a colorspace
  /// conversion (which would invent drift that is not in the artifact).
  private func color(in bitmap: NSBitmapImageRep, atX pixelX: Int, y pixelY: Int) -> NSColor? {
    bitmap.colorAt(x: pixelX, y: pixelY)
  }

  private func components(of color: NSColor) -> [Double] {
    [color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent]
      .map { (Double($0) * 100).rounded() / 100 }
  }

  private func expectColor(
    in bitmap: NSBitmapImageRep,
    atX pixelX: Int,
    y pixelY: Int,
    isApproximately expected: NSColor,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let actual = try #require(color(in: bitmap, atX: pixelX, y: pixelY), sourceLocation: sourceLocation)
    let expected = try #require(expected.usingColorSpace(.sRGB), sourceLocation: sourceLocation)

    let matches =
      abs(actual.redComponent - expected.redComponent) < 0.1
      && abs(actual.greenComponent - expected.greenComponent) < 0.1
      && abs(actual.blueComponent - expected.blueComponent) < 0.1
      && abs(actual.alphaComponent - expected.alphaComponent) < 0.1

    #expect(
      matches,
      "expected approximately \(expected) at (\(pixelX), \(pixelY)), got \(actual)",
      sourceLocation: sourceLocation
    )
  }
}

// MARK: - Fixtures

@MainActor
private func makeFillController(fill: NSColor) -> SnapshotViewController {
  let controller = SnapshotViewController()
  controller.view = FillView(fill: fill)
  return controller
}

/// A root view filling itself with one color and an Auto Layout child pinned `inset` points
/// inside it filling itself with another: the child's solved frame reveals whether the request
/// size was actually laid out.
@MainActor
private func makeInsetChildController(
  rootFill: NSColor,
  childFill: NSColor,
  inset: Double
) -> SnapshotViewController {
  let root = FillView(fill: rootFill)
  let child = FillView(fill: childFill)
  child.translatesAutoresizingMaskIntoConstraints = false
  root.addSubview(child)

  NSLayoutConstraint.activate([
    child.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: inset),
    child.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -inset),
    child.topAnchor.constraint(equalTo: root.topAnchor, constant: inset),
    child.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -inset),
  ])

  let controller = SnapshotViewController()
  controller.view = root
  return controller
}

@MainActor
private func makeDecoratedContainer() -> SnapshotViewController {
  let payload = SnapshotViewController()
  payload.view = NSView()
  return payload.wrappingInContainerViewController()
}

extension NSColor {
  /// Explicit sRGB primaries keep pixel expectations free of generic-RGB conversion drift.
  fileprivate static let srgbRed = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
  fileprivate static let srgbBlue = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
}

private final class FillView: NSView {
  private let fill: NSColor

  init(fill: NSColor) {
    self.fill = fill
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_: NSRect) {
    fill.setFill()
    bounds.fill()
  }
}
#endif
