import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specified sizes.
  public static func sizes(
    _ sizes: SizesSnapshotTrait.Size...
  ) -> Self {
    Self(sizes: sizes)
  }

  /// Allows the snapshot to render to the specified sizes.
  public static func sizes(
    _ sizes: [SizesSnapshotTrait.Size]
  ) -> Self {
    Self(sizes: sizes)
  }
}
