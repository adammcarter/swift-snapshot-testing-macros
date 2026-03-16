import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specified sizes.
  ///
  /// - Parameter sizes: The sizes to render.
  /// - Returns: A trait that applies the specified sizes.
  public static func sizes(
    _ sizes: SizesSnapshotTrait.Size...
  ) -> Self {
    Self(sizes: sizes)
  }

  /// Allows the snapshot to render to the specified sizes.
  ///
  /// - Parameter sizes: An array of sizes to render.
  /// - Returns: A trait that applies the specified sizes.
  public static func sizes(
    _ sizes: [SizesSnapshotTrait.Size]
  ) -> Self {
    Self(sizes: sizes)
  }
}
