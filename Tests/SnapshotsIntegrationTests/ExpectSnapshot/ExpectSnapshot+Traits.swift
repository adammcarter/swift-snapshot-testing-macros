// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import SnapshotTestingMacros

@Suite(
  .theme(.light),
  .sizes(.minimum),
  .record(.missing)
)
struct ExpectSnapshotTraitTests {
  @Test(
    .theme(.dark),
    .padding(.all, 16),
    .diffTool(.default)
  )
  func testLevelTraitsOverrideSuiteTraits() {
    #expectSnapshot(Text("Trait precedence"), named: "dark-padded")
  }

  @Test(.backgroundColor(.red))
  func backgroundColorTraitIsApplied() {
    #expectSnapshot(Text("Background color"), named: "background-red")
  }

  @Suite(.theme(.dark))
  struct Nested {
    @Test(
      .theme(.light),
      .theme(.dark)
    )
    func laterDuplicateTraitWins() {
      #expectSnapshot(Text("Nested precedence"), named: "nested-dark")
    }
  }
}

@MainActor
@Suite(.theme(.dark))
struct RenderedTraitBehaviorTests {
  @Test(
    .theme(.all),
    .sizes(width: 32, height: 32, scale: 1)
  )
  func UIKitThemeTraitRendersDifferentLightAndDarkOutputs() throws {
    let renders = try renderedImages { ThemeProbeView() }

    #expect(renders.count == 2)
    #expect(Set(renders.map(\.data)).count == 2)
  }

  @Test(
    .theme(.light),
    .sizes(width: 32, height: 32, scale: 1)
  )
  func nativeTestTraitOverridesSuiteTraitInRenderedOutput() throws {
    let rendered = try #require(renderedImages { ThemeProbeView() }.only)
    let light = try explicitlyRenderedTheme(.light)
    let dark = try explicitlyRenderedTheme(.dark)

    #expect(rendered.data == light.data)
    #expect(rendered.data != dark.data)
  }

  /*
   Composition is covered as four independent tests rather than one that renders every permutation
   itself. Applying traits programmatically means driving `provideScope` recursively, which sends a
   non-Sendable closure across the nonisolated protocol boundary — and the resulting `RenderedImage`
   holds a `UIImage`, so it cannot cross back. Declaring the traits instead exercises the same code
   path an adopter uses, and `CompositionProbeView`'s fixed 24x16 intrinsic size lets each case
   assert absolute values instead of comparing against a sibling render.

   Those values are expressed in points and scaled by the render's own scale, because `dimensions`
   counts pixels: an unspecified scale follows the simulator's display, so hard-coding a pixel size
   would pass on a 2x device and fail on a 3x one.
   */
  @Test(.sizes(.minimum))
  func noDecorationTraitsLeaveIntrinsicSizeAndBackgroundAlone() throws {
    let rendered = try #require(renderedImages { CompositionProbeView() }.only)

    #expect(rendered.dimensions == rendered.pixels(forPointSize: CGSize(width: 24, height: 16)))
    #expect(try rendered.cornerColor().isApproximatelyRed == false)
  }

  @Test(.sizes(.minimum), .padding(8))
  func paddingTraitGrowsBothAxesWithoutPaintingABackground() throws {
    let rendered = try #require(renderedImages { CompositionProbeView() }.only)

    #expect(rendered.dimensions == rendered.pixels(forPointSize: CGSize(width: 40, height: 32)))
    #expect(try rendered.cornerColor().isApproximatelyRed == false)
  }

  @Test(.sizes(.minimum), .backgroundColor(uiColor: .red))
  func backgroundColorTraitPaintsWithoutChangingSize() throws {
    let rendered = try #require(renderedImages { CompositionProbeView() }.only)

    #expect(rendered.dimensions == rendered.pixels(forPointSize: CGSize(width: 24, height: 16)))
    #expect(try rendered.cornerColor().isApproximatelyRed)
  }

  @Test(.sizes(.minimum), .backgroundColor(uiColor: .red), .padding(8))
  func paddingAndBackgroundTraitsComposeWithoutDroppingEither() throws {
    let rendered = try #require(renderedImages { CompositionProbeView() }.only)

    #expect(rendered.dimensions == rendered.pixels(forPointSize: CGSize(width: 40, height: 32)))
    #expect(try rendered.cornerColor().isApproximatelyRed)
  }

  @Test(
    .theme(.all),
    .sizes(
      .init(width: 32, height: 24, scale: 1),
      .init(width: 48, height: 36, scale: 1)
    )
  )
  func allThemesAndSizesProduceEveryRenderedPermutation() throws {
    let renders = try renderedImages { ThemeProbeView() }
    let rendersByDimensions = Dictionary(grouping: renders, by: \.dimensions)

    #expect(renders.count == 4)
    #expect(
      Set(rendersByDimensions.keys) == [
        .init(width: 32, height: 24),
        .init(width: 48, height: 36),
      ]
    )
    #expect(rendersByDimensions.values.allSatisfy { $0.count == 2 })
    #expect(rendersByDimensions.values.allSatisfy { Set($0.map(\.data)).count == 2 })
  }

  @MainActor
  @Suite(.theme(.light))
  struct Nested {
    @Test(
      .theme(.dark),
      .sizes(width: 32, height: 32, scale: 1)
    )
    func nativeTestTraitOverridesSuiteTraitInRenderedOutput() throws {
      let rendered = try #require(renderedImages { ThemeProbeView() }.only)
      let light = try explicitlyRenderedTheme(.light)
      let dark = try explicitlyRenderedTheme(.dark)

      #expect(rendered.data == dark.data)
      #expect(rendered.data != light.data)
    }
  }
}

private struct RenderedImage {
  let data: Data
  let dimensions: Dimensions
  let image: UIImage

  /// The pixel dimensions a point size renders to at this image's own scale.
  func pixels(forPointSize size: CGSize) -> Dimensions {
    Dimensions(
      width: Int(size.width * image.scale),
      height: Int(size.height * image.scale)
    )
  }

  func cornerColor() throws -> RGBAColor {
    let cgImage = try #require(image.cgImage)
    let croppedImage = try #require(cgImage.cropping(to: CGRect(x: 0, y: 0, width: 1, height: 1)))
    var pixel = [UInt8](repeating: 0, count: 4)
    let context = try #require(
      CGContext(
        data: &pixel,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    )
    context.draw(croppedImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return RGBAColor(red: pixel[0], green: pixel[1], blue: pixel[2], alpha: pixel[3])
  }
}

private struct Dimensions: Hashable {
  let width: Int
  let height: Int
}

private struct RGBAColor {
  let red: UInt8
  let green: UInt8
  let blue: UInt8
  let alpha: UInt8

  var isApproximatelyRed: Bool {
    red > 230 && green < 25 && blue < 25 && alpha > 230
  }
}

@MainActor
private func renderedImages(
  makeView: @escaping @MainActor () throws -> UIView
) throws -> [RenderedImage] {
  let generator = SnapshotViewGenerator(
    displayName: "trait-render-probe",
    configuration: .none,
    makeValue: { _ in try makeView() },
    fileID: #fileID,
    filePath: #filePath,
    line: #line,
    column: #column
  )
  let requests = try AssertionRequestGenerator(viewGenerator: generator).generateRequestsSync()

  return try requests.map { request in
    try renderedImage(request: #require(request as? AssertionRequest<UIImage>))
  }
}

@MainActor
private func explicitlyRenderedTheme(_ theme: UIUserInterfaceStyle) throws -> RenderedImage {
  let context = AssertionRequestContext(
    name: "explicit-theme-probe",
    configurationName: nil,
    traitConfiguration: .init(
      sizes: [.init(width: .fixed(32), height: .fixed(32), scale: 1)],
      theme: .light,
      strategy: .image
    ),
    makeSnapshotView: {
      SnapshotInjectedViewController(view: ThemeProbeView())
    },
    snapshotDirectory: NSTemporaryDirectory(),
    fileID: #fileID,
    filePath: #filePath,
    line: #line,
    column: #column
  )
  let generator = StrategyAssertionRequestGenerator(
    context: context,
    size: CGSize(width: 32, height: 32),
    theme: theme,
    displayScale: 1,
    testName: "explicit-theme-probe"
  )
  let request = try #require(
    generator.generateRequestsSync().first as? AssertionRequest<UIImage>
  )

  return try renderedImage(request: request)
}

@MainActor
private func renderedImage(request: AssertionRequest<UIImage>) throws -> RenderedImage {
  var renderedImage: UIImage?
  request.snapshotting.snapshot(request.view).run { renderedImage = $0 }

  let image = try #require(renderedImage)
  let cgImage = try #require(image.cgImage)
  return RenderedImage(
    data: request.snapshotting.diffing.toData(image),
    dimensions: .init(width: cgImage.width, height: cgImage.height),
    image: image
  )
}

private final class ThemeProbeView: UIView {
  init() {
    super.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    backgroundColor = .systemBackground
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class CompositionProbeView: UIView {
  override var intrinsicContentSize: CGSize { CGSize(width: 24, height: 16) }

  init() {
    super.init(frame: CGRect(x: 0, y: 0, width: 24, height: 16))
    backgroundColor = .clear
    isOpaque = false
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    UIColor.blue.setFill()
    UIBezierPath(rect: rect.insetBy(dx: 4, dy: 4)).fill()
  }
}

extension Collection {
  fileprivate var only: Element? {
    count == 1 ? first : nil
  }
}
#endif
