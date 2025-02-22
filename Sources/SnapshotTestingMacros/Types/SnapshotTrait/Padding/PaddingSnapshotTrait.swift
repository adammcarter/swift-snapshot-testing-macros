#if canImport(SwiftUI)
import SwiftUI
import Testing

public struct PaddingSnapshotTrait: SnapshotTrait {
  public typealias Edge = SwiftUI.Edge

  let insets: EdgeInsets?
  let edges: PaddingSnapshotTrait.Edge.Set?
  let length: CGFloat?

  public var debugDescription: String {
    if let insets {
      "edges: \(insets)"
    }
    else if let edges, let length {
      "edges: \(edges) - \(length)"
    }
    else {
      fatalError("Nil edges shouldn't be a thing. Something bad happened.")
    }
  }

  init(insets: EdgeInsets) {
    self.insets = insets
    self.edges = nil
    self.length = nil
  }

  init(
    edges: PaddingSnapshotTrait.Edge.Set,
    length: CGFloat? = nil
  ) {
    self.insets = nil
    self.edges = edges
    self.length = length
  }
}
#endif
