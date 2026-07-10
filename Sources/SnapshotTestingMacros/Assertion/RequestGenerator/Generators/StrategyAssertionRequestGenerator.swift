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
          snapshotting: makeRecursiveDescriptionSnapshotting(),
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

  /// Builds a recursive-description strategy that honours the request's size, theme, and
  /// display scale so the dump matches the size/theme components baked into the reference
  /// file's name. Without this, the size/theme fan-out would emit N×M identically-generated
  /// text files whose names claim settings that were never applied: the view would dump with
  /// whatever stale frame it happened to have, never the computed request size.
  ///
  /// The settings are applied at render time (not at request-generation time) because the
  /// snapshot value can be a single cached instance shared by every request in the size/theme
  /// fan-out, and all requests are generated before any of them renders — a generation-time
  /// mutation would let the last-generated permutation win for every artifact.
  private func makeRecursiveDescriptionSnapshotting() -> Snapshotting<SnapshotViewController, String> {
    #if canImport(UIKit)
    // pointfree's parameterised strategy re-hosts the view at `size` with the given traits
    // (theme + display scale) and lays it out before dumping, mirroring the `.image` path.
    return .recursiveDescription(on: .init(), size: size, traits: makeTraits())
    #elseif canImport(AppKit)
    // pointfree's AppKit variant never lays out and takes no size or appearance, so apply
    // both here before delegating to it for the dump. The display scale has no textual
    // representation in `_subtreeDescription`, so it cannot affect the artifact.
    let size = size
    let theme = theme

    return Snapshotting<SnapshotView, String>.recursiveDescription
      .pullback { viewController in
        MainActor.assumeIsolated {
          let view = viewController.view
          view.appearance = theme
          view.frame.size = size
          view.needsLayout = true
          view.layoutSubtreeIfNeeded()
          return view
        }
      }
    #endif
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
