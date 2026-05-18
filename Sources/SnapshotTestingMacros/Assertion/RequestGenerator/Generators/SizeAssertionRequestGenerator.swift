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
    get throws {
      try makeSizes()
    }
  }

  func accumulateRequests(for value: SizePair) throws -> [any AssertionRequesting] {
    /*
     Return the view controller that's just gone through the layout process in this generator.
    
     Using the base view would result in a zero size frame as it has not been laid out until this generator.
     */
    let contextWithLaidOutView = AssertionRequestContext(
      name: context.name,
      configurationName: context.configurationName,
      traitConfiguration: context.traitConfiguration,
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

    return try base.generateRequestsSync()
  }

  enum SizeError: LocalizedError {
    case zeroSize
    case zeroWidth
    case zeroHeight
    case noSizesAvailable
    case unexpected(underlying: Error)

    var errorDescription: String? {
      switch self {
        case .zeroSize: "Size is zero for snapshot"
        case .zeroWidth: "Zero width for snapshot"
        case .zeroHeight: "Zero height for snapshot"
        case .noSizesAvailable: "No sizes available for snapshot"
        case .unexpected(let underlying): "Unexpected sizing error: \(underlying.localizedDescription)"
      }
    }

    var underlyingError: Error? {
      guard case .unexpected(let underlying) = self else {
        return nil
      }

      return underlying
    }
  }

  private func makeSizes() throws -> [SizePair] {
    let viewController = try context.makeSnapshotView()

    do {
      let sizes =
        try context
        .traitConfiguration
        .sizes
        .map { traitSize -> SizePair in
          let absoluteSize = traitSize.absoluteSize(for: viewController)

          guard absoluteSize != .zero else {
            throw SizeError.zeroSize
          }

          guard absoluteSize.width > 0 else {
            throw SizeError.zeroWidth
          }

          guard absoluteSize.height > 0 else {
            throw SizeError.zeroHeight
          }

          return .init(
            traitSize: traitSize,
            size: absoluteSize,
            modifiedViewController: viewController
          )
        }

      guard sizes.isEmpty == false else {
        throw SizeError.noSizesAvailable
      }

      return sizes
    }
    catch let error as SizeError {
      throw error
    }
    catch {
      throw SizeError.unexpected(underlying: error)
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
    switch (width, height) {
      case (.fixed(let width), .fixed(let height)):
        .init(width: width, height: height)

      case (.minimum, .minimum):
        viewController.compressedSizeWhenConstrained()

      case (.fixed(let width), .minimum):
        viewController.compressedSizeWhenConstrained(toWidth: width)

      case (.minimum, .fixed(let height)):
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
