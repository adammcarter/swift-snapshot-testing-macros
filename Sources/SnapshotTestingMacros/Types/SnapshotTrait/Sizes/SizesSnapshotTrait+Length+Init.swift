import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specific width and height.
  public static func sizes(
    width: SizesSnapshotTrait.Length,
    height: SizesSnapshotTrait.Length
  ) -> Self {
    Self(
      sizes: [.init(width: width, height: height)]
    )
  }

  /// Allows the snapshot to render to the specific width and a minimum height..
  public static func sizes(
    width: SizesSnapshotTrait.Length
  ) -> Self {
    sizes(width: width, height: .minimum)
  }

  /// Allows the snapshot to render to the specific height and a minimum width.
  public static func sizes(
    height: SizesSnapshotTrait.Length
  ) -> Self {
    sizes(width: .minimum, height: height)
  }

  /// Allows the snapshot to render to the minimum possible size.
  public static func sizes(
    _ length: SizesSnapshotTrait.Length = .minimum
  ) -> Self {
    sizes(width: length, height: length)
  }
}
