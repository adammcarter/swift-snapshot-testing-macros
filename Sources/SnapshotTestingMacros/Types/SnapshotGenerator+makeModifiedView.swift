import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - SwiftUI

extension SnapshotGenerator {

  @MainActor
  static func makeModifiedView<V: SwiftUI.View>(from rootView: V, traits: [SnapshotTrait]) -> SnapshotView {
    modifyingSnapshotView(
      rootView,
      paddingTrait: traits.paddingTrait,
      backgroundColorTrait: traits.backgroundColorTrait
    )
  }

  @MainActor
  private static func modifyingSnapshotView<V: SwiftUI.View>(
    _ rootView: V,
    paddingTrait: PaddingSnapshotTrait?,
    backgroundColorTrait: BackgroundSnapshotTrait?
  ) -> SnapshotView {
    let view = makeSnapshotView {
      if let insets = paddingTrait?.insets {
        rootView
          .padding(insets)
      }
      else if let edges = paddingTrait?.edges {
        rootView
          .padding(edges, paddingTrait?.length)
      }
      else {
        rootView
      }
    }

    view.backgroundColor = nil

    configureBackgroundColor(of: view, for: backgroundColorTrait)

    return view
  }

  @MainActor
  private static func makeSnapshotView<V: SwiftUI.View>(@ViewBuilder from content: () -> V) -> SnapshotView {
    SnapshotHostingController(rootView: content()).view
  }
}

// MARK: - UIKit / AppKit

extension SnapshotGenerator {

  @MainActor
  static func makeModifiedView(from snapshotView: SnapshotView, traits: [SnapshotTrait]) -> SnapshotView {
    modifyingSnapshotView(
      snapshotView,
      paddingTrait: traits.paddingTrait,
      backgroundColorTrait: traits.backgroundColorTrait
    )
  }

  @MainActor
  private static func modifyingSnapshotView(
    _ snapshotView: SnapshotView,
    paddingTrait: PaddingSnapshotTrait?,
    backgroundColorTrait: BackgroundSnapshotTrait?
  ) -> SnapshotView {
    let directionalInsets = paddingTrait?.directionalInsets ?? .zero

    configureBackgroundColor(of: snapshotView, for: backgroundColorTrait)

    guard directionalInsets != .zero else {
      return snapshotView
    }

    let containerView = SnapshotView()

    configureBackgroundColor(of: containerView, for: backgroundColorTrait)

    snapshotView.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(snapshotView)

    NSLayoutConstraint.activate([
      snapshotView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: directionalInsets.leading),
      snapshotView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -directionalInsets.trailing),
      snapshotView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: directionalInsets.top),
      snapshotView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -directionalInsets.bottom),
    ])

    return containerView
  }

  @MainActor
  private static func configureBackgroundColor(of view: SnapshotView, for backgroundTrait: BackgroundSnapshotTrait?) {
    guard let backgroundColor = backgroundTrait?.backgroundColor else {
      return
    }

    view.backgroundColor = backgroundColor
  }
}

#if canImport(AppKit)
@MainActor
extension NSView {
  fileprivate var backgroundColor: NSColor? {
    get { layer?.backgroundColor.flatMap { .init(cgColor: $0) } }
    set { layer?.backgroundColor = newValue?.cgColor }
  }
}
#endif

// MARK: - Traits

extension [SnapshotTrait] {
  fileprivate var paddingTrait: PaddingSnapshotTrait? { first(as: PaddingSnapshotTrait.self) }
  fileprivate var backgroundColorTrait: BackgroundSnapshotTrait? { first(as: BackgroundSnapshotTrait.self) }
}

extension PaddingSnapshotTrait {
  fileprivate var directionalInsets: NSDirectionalEdgeInsets? {
    if let insets {
      .init(insets)
    }
    else if let edges, let length {
      .init(
        top: edges.contains(.top) ? length : 0,
        leading: edges.contains(.leading) ? length : 0,
        bottom: edges.contains(.bottom) ? length : 0,
        trailing: edges.contains(.trailing) ? length : 0
      )
    }
    else {
      nil
    }
  }
}

#if canImport(AppKit)
extension NSDirectionalEdgeInsets: @retroactive Equatable {
  public static func == (lhs: NSDirectionalEdgeInsets, rhs: NSDirectionalEdgeInsets) -> Bool {
    lhs.bottom == rhs.bottom && lhs.leading == rhs.leading && lhs.top == rhs.top && lhs.trailing == rhs.trailing
  }
}

extension NSDirectionalEdgeInsets {
  static var zero: NSDirectionalEdgeInsets {
    .init(top: 0, leading: 0, bottom: 0, trailing: 0)
  }
}
#endif
