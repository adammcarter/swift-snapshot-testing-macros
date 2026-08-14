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
     Reuse the view controller that `makeSizes()` measured rather than building a fresh one.

     Measurement only lays the view out for `.minimum` dimensions — fully `.fixed` sizes never
     touch the view here — so the view's frame is not guaranteed to match the computed size at
     this point. Every strategy applies the computed size (and theme/scale) itself at render
     time; see `StrategyAssertionRequestGenerator`.
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
    case invalidFixedWidth(Double)
    case invalidFixedHeight(Double)
    case invalidScale(Double)
    case noSizesAvailable
    case unexpected(underlying: Error)

    var errorDescription: String? {
      switch self {
        case .zeroSize: "Size is zero for snapshot"
        case .zeroWidth: "Zero width for snapshot"
        case .zeroHeight: "Zero height for snapshot"
        case .invalidFixedWidth(let value):
          "Invalid fixed width (\(value)) for snapshot: fixed lengths must be positive and finite"
        case .invalidFixedHeight(let value):
          "Invalid fixed height (\(value)) for snapshot: fixed lengths must be positive and finite"
        case .invalidScale(let value):
          "Invalid scale (\(value)) for snapshot: scale must be positive and finite, or nil to inherit"
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
          try traitSize.validate()

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
  /*
   Rejecting non-positive/non-finite requests up front keeps every width/height combination
   consistent: without this, a `.fixed(0)` (or negative) length combined with `.minimum` fell
   into the measurement path, whose old `0` sentinel silently dropped the constraint and
   measured the fully-compressed size — a passing snapshot at intrinsic size when the user
   asked for width 0/-50 — while the same length next to a `.fixed` partner failed, and
   negative values were misreported as "zero" errors.
   */
  fileprivate func validate() throws {
    if case .fixed(let width) = width, isValidLength(width) == false {
      throw SizeAssertionRequestGenerator.SizeError.invalidFixedWidth(width)
    }

    if case .fixed(let height) = height, isValidLength(height) == false {
      throw SizeAssertionRequestGenerator.SizeError.invalidFixedHeight(height)
    }

    if let scale, isValidLength(scale) == false {
      throw SizeAssertionRequestGenerator.SizeError.invalidScale(scale)
    }
  }

  private nonisolated func isValidLength(_ value: Double) -> Bool {
    value > 0 && value.isFinite
  }

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
    toWidth width: Double? = nil,
    toHeight height: Double? = nil
  ) -> CGSize {
    let containerViewController = SnapshotViewController()
    containerViewController.embedChild(self)

    if let width {
      containerViewController.view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    if let height {
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
