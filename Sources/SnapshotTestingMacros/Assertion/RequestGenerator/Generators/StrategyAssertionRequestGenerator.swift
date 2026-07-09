import Foundation
import SnapshotSupport
import SnapshotTesting

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct StrategyAssertionRequestGenerator: AssertionRequestGenerating {
  let context: AssertionRequestContext

  let size: CGSize
  let theme: SnapshotTheme
  let displayScale: Double
  let testName: String

  func generateRequestsSync() throws -> [any AssertionRequesting] {
    let request: any AssertionRequesting

    switch context.traitConfiguration.strategy {
      case .recursiveDescription:
        request = AssertionRequest(
          view: try context.makeSnapshotView(),
          snapshotting: .recursiveDescription,
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )

      case .image:
        #if canImport(UIKit)
        request = AssertionRequest(
          view: try context.makeSnapshotView(),
          snapshotting: .image(
            size: size,
            traits: makeTraits()
          ),
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )
        #elseif canImport(AppKit)
        request = AssertionRequest(
          view: try context.makeSnapshotView(),
          snapshotting: makeThemedImageSnapshotting(),
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )
        #endif
    }

    return [request]
  }

  #if canImport(AppKit)
  /// Wraps the image strategy so the theme's `NSAppearance` is applied to the snapshot view
  /// hierarchy immediately before rendering, making dynamic colors resolve per theme. This mirrors
  /// the UIKit path, where `userInterfaceStyle` is passed through the snapshotting strategy's
  /// trait collection and resolved at render time.
  ///
  /// The appearance must be applied at render time rather than when the request is generated:
  /// the snapshot value can be a single cached instance shared by every request in the theme
  /// fan-out, and all requests are generated before any of them renders — so a generation-time
  /// mutation would let the last-generated theme win for every artifact.
  private func makeThemedImageSnapshotting() -> Snapshotting<SnapshotViewController, NSImage> {
    let theme = theme

    return Snapshotting<SnapshotViewController, NSImage>
      .image(size: size)
      .pullback { viewController in
        MainActor.assumeIsolated {
          viewController.view.appearance = theme
        }

        return viewController
      }
  }
  #endif

  #if canImport(UIKit)
  func makeTraits() -> UITraitCollection {
    if #available(iOS 17.0, *) {
      UITraitCollection {
        $0.displayScale = displayScale
        $0.userInterfaceStyle = theme
      }
    }
    else {
      UITraitCollection(traitsFrom: [
        .init(displayScale: displayScale),
        .init(userInterfaceStyle: theme),
      ])
    }
  }
  #endif
}
