import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specific width and height.
  ///
  /// - Parameters:
  ///   - width: The width to use.
  ///   - height: The height to use.
  ///   - scale: A scale to apply to the sizing. Use `2.0` for @2x, `3.0` for @3x. Set to `nil` to inherit from the test device.
  /// - Returns: A trait that applies the specific size.
  public static func sizes(
    width: SizesSnapshotTrait.Length,
    height: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) -> Self {
    Self(
      sizes: [
        .init(width: width, height: height, scale: scale)
      ]
    )
  }

  /// Allows the snapshot to render to the specific width and a minimum height.
  ///
  /// - Parameters:
  ///   - width: The width to use.
  ///   - scale: A scale to apply to the sizing. Use `2.0` for @2x, `3.0` for @3x. Set to `nil` to inherit from the test device.
  /// - Returns: A trait that applies the width with minimum height.
  public static func sizes(
    width: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) -> Self {
    sizes(width: width, height: .minimum, scale: scale)
  }

  /// Allows the snapshot to render to the specific height and a minimum width.
  ///
  /// - Parameters:
  ///   - height: The height to use.
  ///   - scale: A scale to apply to the sizing. Use `2.0` for @2x, `3.0` for @3x. Set to `nil` to inherit from the test device.
  /// - Returns: A trait that applies the height with minimum width.
  public static func sizes(
    height: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) -> Self {
    sizes(width: .minimum, height: height, scale: scale)
  }

  /// Allows the snapshot to render to the minimum possible size.
  ///
  /// - Parameters:
  ///   - length: The length to use for both width and height. Defaults to `.minimum`.
  ///   - scale: A scale to apply to the sizing. Use `2.0` for @2x, `3.0` for @3x. Set to `nil` to inherit from the test device.
  /// - Returns: A trait that applies minimum sizing.
  public static func sizes(
    _ length: SizesSnapshotTrait.Length = .minimum,
    scale: Double? = nil
  ) -> Self {
    sizes(width: length, height: length, scale: scale)
  }
}
