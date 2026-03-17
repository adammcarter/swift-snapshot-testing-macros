import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specific width and height.
  ///
  /// - Parameters:
  ///   - width: The width to use.
  ///   - height: The height to use.
  ///   - scale: A scale to apply to the sizing. Use `2.0` for @2x, `3.0` for @3x. Set to `nil` to inherit from the test device.
  /// - Returns: A trait that applies the specific size.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   // explicit `.fixed()`
  ///   @SnapshotTest(.sizes(width: .fixed(300), height: .fixed(200)))
  ///   func fixedLength() -> some View { ... }
  ///
  ///   // integer literal
  ///   @SnapshotTest(.sizes(width: 300, height: 200))
  ///   func integerLiteralLength() -> some View { ... }
  ///
  ///   // float literal
  ///   @SnapshotTest(.sizes(width: 300.0, height: 200.0))
  ///   func floatingPointLiteralLength() -> some View { ... }
  ///
  ///   // explicit scale
  ///   @SnapshotTest(.sizes(width: 300, height: 200, scale: 2.0))
  ///   func scaledLength() -> some View { ... }
  /// }
  /// ```
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
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   // explicit `.fixed()`
  ///   @SnapshotTest(.sizes(width: .fixed(300)))
  ///   func fixedLengthWidth() -> some View { ... }
  ///
  ///   // integer literal
  ///   @SnapshotTest(.sizes(width: 300))
  ///   func integerLiteralWidth() -> some View { ... }
  ///
  ///   // float literal
  ///   @SnapshotTest(.sizes(width: 300.0))
  ///   func floatingPointLiteralWidth() -> some View { ... }
  ///
  ///   // explicit scale
  ///   @SnapshotTest(.sizes(width: 300, scale: 2.0))
  ///   func scaledWidth() -> some View { ... }
  /// }
  /// ```
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
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   // explicit `.fixed()`
  ///   @SnapshotTest(.sizes(height: .fixed(200)))
  ///   func fixedLengthHeight() -> some View { ... }
  ///
  ///   // integer literal
  ///   @SnapshotTest(.sizes(height: 200))
  ///   func integerLiteralHeight() -> some View { ... }
  ///
  ///   // float literal
  ///   @SnapshotTest(.sizes(height: 200.0))
  ///   func floatingPointLiteralHeight() -> some View { ... }
  ///
  ///   // explicit scale
  ///   @SnapshotTest(.sizes(height: 200, scale: 2.0))
  ///   func scaledHeight() -> some View { ... }
  /// }
  /// ```
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
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.sizes(.minimum))
  ///   func minimumLength() -> some View { ... }
  ///
  ///   // explicit scale
  ///   @SnapshotTest(.sizes(.minimum, scale: 2.0))
  ///   func scaledMinimumLength() -> some View { ... }
  /// }
  /// ```
  public static func sizes(
    _ length: SizesSnapshotTrait.Length = .minimum,
    scale: Double? = nil
  ) -> Self {
    sizes(width: length, height: length, scale: scale)
  }
}
