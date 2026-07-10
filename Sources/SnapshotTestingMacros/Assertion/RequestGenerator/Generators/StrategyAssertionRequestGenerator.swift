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
          snapshotting: makeImageSnapshotting(),
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
  /// Builds an image strategy that performs the full render pass — offscreen window hosting at
  /// the request size, the theme's `NSAppearance`, the decorator background, an Auto Layout
  /// pass, and the request's display scale — via ``AppKitImageRenderer``. This mirrors the UIKit
  /// path, where the size is re-hosted per request and `userInterfaceStyle`/`displayScale` are
  /// passed through the snapshotting strategy's trait collection and resolved at render time.
  ///
  /// Everything must be applied at render time rather than when the request is generated: the
  /// snapshot value can be a single cached instance shared by every request in the size/theme
  /// fan-out, and all requests are generated before any of them renders — so a generation-time
  /// mutation would let the last-generated permutation win for every artifact.
  private func makeImageSnapshotting() -> Snapshotting<SnapshotViewController, NSImage> {
    let size = size
    let theme = theme
    let displayScale = displayScale
    // Captured now, while the decorator trait's task-local is still bound; the render itself
    // runs outside that scope. Re-applying the color per render (under the themed appearance)
    // lets dynamic colors resolve differently for the light and dark artifacts.
    let backgroundColor = __SnapshotViewDecoratorConfiguration.value?.backgroundColor

    return Snapshotting<NSImage, NSImage>.image
      .pullback { viewController in
        MainActor.assumeIsolated {
          AppKitImageRenderer.render(
            viewController: viewController,
            size: size,
            displayScale: displayScale,
            appearance: theme,
            backgroundColor: backgroundColor
          )
        }
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
