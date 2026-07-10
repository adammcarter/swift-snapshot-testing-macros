#if canImport(AppKit)
import AppKit
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Regression tests for frame-based payloads under `.minimum` size measurement: a view that is
/// sized purely by its `frame` (no Auto Layout constraints, no intrinsic content size — the shape
/// produced by the plain-view `#expectSnapshot` overload and by views migrated from pointfree's
/// `assertSnapshot(of: view, as: .image)`) must snapshot at its frame size.
///
/// The measurement path embeds the payload with `translatesAutoresizingMaskIntoConstraints =
/// false`, which discards frame-based sizing entirely: bare payloads collapsed to zero and threw
/// `SizeError.zeroSize`, and padded payloads silently recorded a padding-only artifact with an
/// invisible zero-sized payload inside it.
@MainActor
struct FrameBasedViewSizingTests {
  @Test
  func frameBasedViewMeasuresAtItsFrameSize() throws {
    let payload = SnapshotViewController()
    payload.view = FillView(fill: .srgbRed, width: 200, height: 100)

    let request = try firstImageRequest { payload }
    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 200)
    #expect(bitmap.pixelsHigh == 100)
    try expectColor(in: bitmap, atX: 100, y: 50, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 2, y: 2, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 197, y: 97, isApproximately: .srgbRed)
  }

  /// The padded case is the silent one: the decorator's container measured as insets-only
  /// (payload collapsed to zero), so a 32x32 padding-only reference recorded green forever.
  @Test
  func paddedFrameBasedViewMeasuresAtFrameSizePlusInsets() throws {
    let payload = SnapshotViewController()
    payload.view = FillView(fill: .srgbRed, width: 200, height: 100)

    let container = payload.wrappingInContainerViewController(
      insets: .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    )

    let request = try firstImageRequest { container }
    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 232)
    #expect(bitmap.pixelsHigh == 132)
    // The payload must actually be visible inside the padding, not a zero-sized ghost.
    try expectColor(in: bitmap, atX: 116, y: 66, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 20, y: 20, isApproximately: .srgbRed)
    try expectColor(in: bitmap, atX: 211, y: 111, isApproximately: .srgbRed)
  }

  /// Views that size themselves through Auto Layout must keep doing so: the frame-size pin must
  /// not apply once the payload carries its own constraints.
  @Test
  func constraintSizedViewIsUnaffectedByFramePreservation() throws {
    let view = FillView(fill: .srgbRed, width: 999, height: 999)
    view.widthAnchor.constraint(equalToConstant: 120).isActive = true
    view.heightAnchor.constraint(equalToConstant: 60).isActive = true

    let payload = SnapshotViewController()
    payload.view = view

    let request = try firstImageRequest { payload }
    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == 120)
    #expect(bitmap.pixelsHigh == 60)
  }

  /// Views with an intrinsic content size (labels, etc.) must keep measuring intrinsically.
  @Test
  func intrinsicallySizedViewIsUnaffectedByFramePreservation() throws {
    let label = NSTextField(labelWithString: "Intrinsic sizing")
    label.sizeToFit()
    let intrinsicSize = label.intrinsicContentSize

    let payload = SnapshotViewController()
    payload.view = label

    let request = try firstImageRequest { payload }
    let bitmap = try renderedBitmap(request: request)

    #expect(bitmap.pixelsWide == Int(intrinsicSize.width.rounded()))
    #expect(bitmap.pixelsHigh == Int(intrinsicSize.height.rounded()))
  }

  /// A genuinely zero-sized frame-based payload must still fail loudly rather than record.
  @Test
  func zeroFrameViewStillThrowsZeroSize() throws {
    let payload = SnapshotViewController()
    payload.view = NSView(frame: .zero)

    let generator = SizeAssertionRequestGenerator(context: makeContext { payload })

    #expect(throws: SizeAssertionRequestGenerator.SizeError.self) {
      try generator.generateRequestsSync()
    }
  }

  // MARK: - Request construction

  private func firstImageRequest(
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController
  ) throws -> AssertionRequest<NSImage> {
    let generator = SizeAssertionRequestGenerator(context: makeContext(makeSnapshotView: makeSnapshotView))

    let requests = try generator.generateRequestsSync()
    return try #require(requests.first as? AssertionRequest<NSImage>)
  }

  private func makeContext(
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController
  ) -> AssertionRequestContext {
    AssertionRequestContext(
      name: "frameBasedSizingProbe",
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

  private func renderedBitmap(request: AssertionRequest<NSImage>) throws -> NSBitmapImageRep {
    var renderedImage: NSImage?
    request.snapshotting.snapshot(request.view).run { renderedImage = $0 }

    let image = try #require(renderedImage)
    let bitmap = image.representations.compactMap { $0 as? NSBitmapImageRep }.first
    return try #require(bitmap)
  }

  private func expectColor(
    in bitmap: NSBitmapImageRep,
    atX pixelX: Int,
    y pixelY: Int,
    isApproximately expected: NSColor,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let actual = try #require(bitmap.colorAt(x: pixelX, y: pixelY), sourceLocation: sourceLocation)
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

extension NSColor {
  fileprivate static let srgbRed = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
}

/// A frame-based view: sized purely by its initial `frame`, with no constraints of its own and
/// no intrinsic content size, filling itself with a solid color so its rendered extent is
/// observable in the bitmap.
private final class FillView: NSView {
  private let fill: NSColor

  init(fill: NSColor, width: Double, height: Double) {
    self.fill = fill
    super.init(frame: .init(x: 0, y: 0, width: width, height: height))
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
