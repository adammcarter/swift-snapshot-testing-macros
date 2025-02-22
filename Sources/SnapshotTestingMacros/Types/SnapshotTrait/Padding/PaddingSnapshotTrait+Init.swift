#if canImport(SwiftUI)
import SwiftUI
import Testing

/*
 The below callers match the .padding() SwiftUI modifier.
 */extension SnapshotTrait where Self == PaddingSnapshotTrait {
  /**
    Apply a padding to the views when the snapshot is taken.
    */
  public static func padding(
    _ insets: EdgeInsets
  ) -> Self {
    Self(insets: insets)
  }

  /**
    Apply a padding to the views when the snapshot is taken, if length is nil a default padding is added.
    */
  public static func padding(
    _ edges: PaddingSnapshotTrait.Edge.Set = .all,
    _ length: CGFloat? = nil
  ) -> Self {
    Self(edges: edges, length: length)
  }

  /**
    Apply a padding to the views when the snapshot is taken around all edges.
    */
  public static func padding(
    _ length: CGFloat
  ) -> Self {
    Self(edges: .all, length: length)
  }

  /**
    Apply a padding to the views when the snapshot is taken with a default value.
    */
  public static var padding: Self {
    .padding()
  }
}
#endif
