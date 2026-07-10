#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension SnapshotViewController {
  func wrappingInContainerViewController(
    insets: NSDirectionalEdgeInsets = .zero
  ) -> SnapshotViewController {
    let parentViewController = SnapshotViewController()
    parentViewController.embedChild(self, insets: insets)

    return parentViewController
  }
}

extension SnapshotViewController {
  func embedChild(
    _ childController: SnapshotViewController,
    insets: NSDirectionalEdgeInsets = .zero
  ) {
    addChild(childController)

    Self.preserveFrameBasedSize(of: childController.view)
    childController.view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(childController.view)

    NSLayoutConstraint.activate([
      childController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
      childController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
      childController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
      childController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
    ])

    #if canImport(UIKit)
    childController.didMove(toParent: self)
    #endif
  }

  /// A frame-based child view — no *external* sizing (no constraint on its own width/height and
  /// no intrinsic content size) — carries its size solely in `frame`. This is the shape produced
  /// by the plain-view `#expectSnapshot` overloads and by views migrated from pointfree's
  /// `assertSnapshot(of: view, as: .image)`, including the common migration shape of a root that
  /// lays its own subviews out with *internal* Auto Layout constraints.
  ///
  /// Disabling `translatesAutoresizingMaskIntoConstraints` below discards that frame size, so
  /// `.minimum` measurement would collapse the view to zero: bare payloads error with
  /// `SizeError.zeroSize` despite having a perfectly valid frame, and padded payloads silently
  /// record an insets-only artifact with an invisible zero-sized payload inside it.
  ///
  /// Pinning the current frame size keeps such views measurable under Auto Layout. The pin is
  /// below required priority so the required edge constraints of an explicitly sized host (a
  /// fixed-size request or the render pass's window) still stretch the view. Views that size
  /// themselves through a width/height constraint or an intrinsic content size are left
  /// untouched, and a child that was already pinned by an earlier embedding is not pinned twice
  /// (the earlier pin is a width/height constraint on the child).
  ///
  /// The frame-based decision keys on whether the view constrains its *own* width or height, not
  /// on whether it holds any constraints at all: a root's `constraints` also include internal
  /// constraints between its subviews (`centerX`, edge pins, …), whose presence must not be
  /// mistaken for external sizing.
  private static func preserveFrameBasedSize(of childView: SnapshotView) {
    guard !hasOwnSizeConstraint(childView) else {
      return
    }

    let intrinsicSize = childView.intrinsicContentSize
    guard
      intrinsicSize.width == SnapshotView.noIntrinsicMetric,
      intrinsicSize.height == SnapshotView.noIntrinsicMetric
    else {
      return
    }

    let frameSize = childView.frame.size
    var sizeConstraints: [NSLayoutConstraint] = []

    if frameSize.width > 0 {
      sizeConstraints.append(childView.widthAnchor.constraint(equalToConstant: frameSize.width))
    }

    if frameSize.height > 0 {
      sizeConstraints.append(childView.heightAnchor.constraint(equalToConstant: frameSize.height))
    }

    for sizeConstraint in sizeConstraints {
      sizeConstraint.priority = .defaultHigh
    }

    NSLayoutConstraint.activate(sizeConstraints)
  }

  /// Whether the view constrains its own width or height — the signal that it is externally
  /// sized by Auto Layout rather than by its `frame`. Only constraints whose *first* item is the
  /// view with a width/height attribute count: those determine the view's own dimension (a
  /// constant pin, or the frame pin added by an earlier embedding). Constraints where the view is
  /// the second item (a subview pinned to the view's width) or that carry a non-size attribute
  /// (`centerX`, edge pins between subviews) are internal layout and must not be mistaken for
  /// external sizing.
  private static func hasOwnSizeConstraint(_ view: SnapshotView) -> Bool {
    view.constraints.contains { constraint in
      constraint.firstItem === view
        && (constraint.firstAttribute == .width || constraint.firstAttribute == .height)
    }
  }
}
