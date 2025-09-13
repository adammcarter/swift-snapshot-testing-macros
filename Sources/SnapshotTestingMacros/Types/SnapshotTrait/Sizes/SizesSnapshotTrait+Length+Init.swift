import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specific width and height.
  /// - Parameters:
  ///   - width: The width to use
  ///   - height: The height to use
  ///   - scale: A scale to apply to the sizing. Use `2.0` to render a reference image of a @2x display, `3.0` for a @3x display, etc. Set this to `nil` to inherit the scale of the device tests are being run on.
  /// - Returns: Sizes trait
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
  /// - Parameters:
  ///   - width: The width to use
  ///   - scale: A scale to apply to the sizing. Use `2.0` to render a reference image of a @2x display, `3.0` for a @3x display, etc. Set this to `nil` to inherit the scale of the device tests are being run on.
  /// - Returns: Sizes trait
  public static func sizes(
    width: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) -> Self {
    sizes(width: width, height: .minimum, scale: scale)
  }

  /// Allows the snapshot to render to the specific height and a minimum width.
  /// - Parameters:
  ///   - height: The height to use
  ///   - scale: A scale to apply to the sizing. Use `2.0` to render a reference image of a @2x display, `3.0` for a @3x display, etc. Set this to `nil` to inherit the scale of the device tests are being run on.
  /// - Returns: Sizes trait
  public static func sizes(
    height: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) -> Self {
    sizes(width: .minimum, height: height, scale: scale)
  }

  /// Allows the snapshot to render to the minimum possible size.
  /// - Parameters:
  ///   - length: The length to use for width and height
  ///   - scale: A scale to apply to the sizing. Use `2.0` to render a reference image of a @2x display, `3.0` for a @3x display, etc. Set this to `nil` to inherit the scale of the device tests are being run on.
  /// - Returns: Sizes trait
  public static func sizes(
    _ length: SizesSnapshotTrait.Length = .minimum,
    scale: Double? = nil
  ) -> Self {
    sizes(width: length, height: length, scale: scale)
  }
}
