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
    /*
     AppKit has no deterministic device scale to inherit: `NSScreen.main`'s backing scale depends
     on the machine running the tests, which would make committed references differ between
     Retina and non-Retina machines. An unspecified scale therefore uses a fixed value.

     That value is 2 rather than 1. Determinism only requires the scale to be fixed; which fixed
     value to pick is a separate, fidelity question. Every shipping Mac is Retina, so rendering
     at 1x would test a configuration no user sees, and would make the hairlines, single-pixel
     borders and text antialiasing that snapshots exist to catch unrepresentable. Pass `scale:`
     explicitly for any other density.
     */
    2.0
    #endif
  }()
}

#if canImport(AppKit)
extension NSAppearance {
  static var light: SnapshotTheme { NSAppearance(named: .aqua)! }
  static var dark: SnapshotTheme { NSAppearance(named: .darkAqua)! }
}
#endif
