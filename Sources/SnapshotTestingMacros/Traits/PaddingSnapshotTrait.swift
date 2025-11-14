#if canImport(SwiftUI)
import SnapshotSupport
import SwiftUI
import Testing

public struct PaddingSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, __SnapshotTestScopingViewDecorator {
  public var debugDescription: String {
    insetKind.debugDescription
  }

  private let insetKind: InsetKind

  init(insets: EdgeInsets) {
    self.insetKind = .insets(insets)
  }

  init(
    edges: PaddingSnapshotTrait.Edge.Set,
    length: CGFloat?
  ) {
    self.insetKind = .edges(edges, length: length)
  }

  public func updateConfiguration(_ configuration: inout __SnapshotViewDecoratorConfiguration) async {
    configuration.padding = await insetKind.directionalInsets
  }

  public typealias Edge = SwiftUI.Edge

  private enum InsetKind: CustomDebugStringConvertible {
    case insets(EdgeInsets)
    case edges(PaddingSnapshotTrait.Edge.Set, length: CGFloat?)

    var debugDescription: String {
      switch self {
        case .edges(let edges, let length):
          "edges: \(edges) - \(length?.formatted() ?? "<default>")"

        case .insets(let insets):
          "edges: \(insets)"
      }
    }

    @MainActor
    var directionalInsets: NSDirectionalEdgeInsets {
      switch self {
        case .edges(let edges, let length):
          #warning("TODO: Ideally this would use the actual SwiftUI/UIKit default padding value (calculated by SwiftUI/UIKit)")
          let defaultMargins = NSDirectionalEdgeInsets(all: 16)

          return .init(
            top: edges.contains(.top) ? length ?? defaultMargins.top : 0,
            leading: edges.contains(.leading) ? length ?? defaultMargins.leading : 0,
            bottom: edges.contains(.bottom) ? length ?? defaultMargins.bottom : 0,
            trailing: edges.contains(.trailing) ? length ?? defaultMargins.trailing : 0
          )

        case .insets(let insets):
          return .init(insets)
      }
    }
  }
}
#endif
