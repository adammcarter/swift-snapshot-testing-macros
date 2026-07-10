import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ThemeAssertionRequestGenerator: AccumulatedAssertionRequestGenerating {
  let context: AssertionRequestContext

  let traitSize: SizesSnapshotTrait.Size
  let size: CGSize

  var values: any Collection<SnapshotTheme> {
    switch context.traitConfiguration.theme {
      case .all: [.light, .dark]
      case .dark: [.dark]
      case .light: [.light]
    }
  }

  func accumulateRequests(for theme: SnapshotTheme) throws -> [any AssertionRequesting] {
    let base = NameAssertionRequestGenerator(
      context: context,
      traitSize: traitSize,
      size: size,
      theme: theme,
      displayScale: makeDisplayScale(sizeTrait: traitSize)
    )

    return try base.generateRequestsSync()
  }

  private func makeDisplayScale(sizeTrait: SizesSnapshotTrait.Size) -> Double {
    sizeTrait.scale ?? Self.windowScale
  }

  private static let windowScale: Double = {
    #if canImport(UIKit)
    UIWindow().traitCollection.displayScale
    #elseif canImport(AppKit)
    // AppKit has no deterministic device scale to inherit: `NSScreen.main`'s backing scale
    // depends on the machine running the tests, which would make committed references differ
    // between Retina and non-Retina machines. An unspecified scale therefore renders at one
    // pixel per point; pass `scale:` explicitly for @2x/@3x output.
    1.0
    #endif
  }()
}

#if canImport(AppKit)
extension NSAppearance {
  static var light: SnapshotTheme { NSAppearance(named: .aqua)! }
  static var dark: SnapshotTheme { NSAppearance(named: .darkAqua)! }
}
#endif
