import SnapshotSupport

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

struct SizeAssertionRequestGenerator: AccumulatedAssertionRequestGenerating {
  let context: AssertionRequestContext

  var values: any Collection<SizePair> {
    get async throws {
      return try await makeSizes()
    }
  }

  func accumulateRequests(for value: SizePair) async throws -> [any AssertionRequesting] {
    /*
     Return the view controller that's just gone through the layout process in this generator.

     Using the base view would result in a zero size frame as it has not been laid out until this generator.
     */
    let contextWithLaidOutView = AssertionRequestContext(
      name: context.name,
      makeSnapshotView: { value.modifiedViewController },
      snapshotDirectory: context.snapshotDirectory,
      fileID: context.fileID,
      filePath: context.filePath,
      line: context.line,
      column: context.column
    )

    let base = ThemeAssertionRequestGenerator(
      context: contextWithLaidOutView,
      traitSize: value.traitSize,
      size: value.size
    )

    return try await base.generateRequests()
  }

  #warning("TODO: Add 'SizeError' instead of using strings above")

  private func makeSizes() async throws -> [SizePair] {
    let viewController = try await context.makeSnapshotView()

    do {
      let sizes =
        try SizesSnapshotTrait
        .current
        .compactMap { traitSize -> SizePair in
          let absoluteSize = traitSize.absoluteSize(for: viewController)

          guard absoluteSize != .zero else {
            throw "size is zero for snapshot"
          }

          guard absoluteSize.width > 0 else {
            throw "zero width for snapshot"
          }

          guard absoluteSize.height > 0 else {
            throw "zero height for snapshot"
          }

          return .init(
            traitSize: traitSize,
            size: absoluteSize,
            modifiedViewController: viewController
          )
        }

      guard sizes.isEmpty == false else {
        throw "no sizes available for snapshot"
      }

      return sizes
    }
    catch let error as String {
      throw error
    }
    catch {
      fatalError("Caught unexpected error: \(error.localizedDescription)")
    }
  }

  struct SizePair {
    let traitSize: SizesSnapshotTrait.Size
    let size: CGSize
    let modifiedViewController: SnapshotViewController
  }
}

@MainActor
extension SizesSnapshotTrait.Size {
  fileprivate func absoluteSize(for viewController: SnapshotViewController) -> CGSize {
    return switch (width, height) {
      case let (.fixed(width), .fixed(height)):
        .init(width: width, height: height)

      case (.minimum, .minimum):
        viewController.compressedSizeWhenConstrained()

      case let (.fixed(width), .minimum):
        viewController.compressedSizeWhenConstrained(toWidth: width)

      case let (.minimum, .fixed(height)):
        viewController.compressedSizeWhenConstrained(toHeight: height)
    }
  }
}

extension SnapshotViewController {
  fileprivate func compressedSizeWhenConstrained(
    toWidth width: Double = 0,
    toHeight height: Double = 0
  ) -> CGSize {
    let containerViewController = SnapshotViewController()
    containerViewController.embedChild(self)

    if width > 0 {
      containerViewController.view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    if height > 0 {
      containerViewController.view.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    containerViewController.view.forceLayout()

    return containerViewController.view.compressedSize()
  }
}

extension SnapshotView {
  fileprivate func forceLayout() {
    #if canImport(UIKit)
    setNeedsLayout()
    layoutIfNeeded()
    #elseif canImport(AppKit)
    needsLayout = true
    layoutSubtreeIfNeeded()
    #endif
  }

  fileprivate func compressedSize() -> CGSize {
    #if canImport(UIKit)
    systemLayoutSizeFitting(SnapshotView.layoutFittingCompressedSize)
    #elseif canImport(AppKit)
    fittingSize
    #endif
  }
}
