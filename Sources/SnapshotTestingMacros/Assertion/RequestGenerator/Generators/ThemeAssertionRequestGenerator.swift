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
    switch ThemeSnapshotTrait.current {
      case .all: [.light, .dark]
      case .dark: [.dark]
      case .light: [.light]
    }
  }

  func accumulateRequests(for theme: SnapshotTheme) async throws -> [any AssertionRequesting] {
    let base = NameAssertionRequestGenerator(
      context: context,
      traitSize: traitSize,
      size: size,
      theme: theme,
      displayScale: makeDisplayScale(sizeTrait: traitSize)
    )

    return try await base.generateRequests()
  }

  private func makeDisplayScale(sizeTrait: SizesSnapshotTrait.Size) -> Double {
    sizeTrait.scale ?? Self.windowScale
  }

  private static let windowScale: Double = {
    #if canImport(UIKit)
    UIWindow().traitCollection.displayScale
    #elseif canImport(AppKit)
    NSScreen.main.flatMap {
      Double($0.backingScaleFactor)
    } ?? 1.0
    #endif
  }()
}

#if canImport(AppKit)
extension NSAppearance {
  fileprivate static var light: SnapshotTheme { NSAppearance(named: .aqua)! }
  fileprivate static var dark: SnapshotTheme { NSAppearance(named: .darkAqua)! }
}
#endif
