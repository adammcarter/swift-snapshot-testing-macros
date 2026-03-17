import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the specified sizes.
  ///
  /// - Parameter sizes: The sizes to render.
  /// - Returns: A trait that applies the specified sizes.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.sizes(
  ///     .init(width: .fixed(300), height: .fixed(200)),
  ///     .init(width: .fixed(400), height: .fixed(300))
  ///   ))
  ///   func myView() -> some View { ... }
  /// }
  /// ```
  public static func sizes(
    _ sizes: SizesSnapshotTrait.Size...
  ) -> Self {
    Self(sizes: sizes)
  }

  /// Allows the snapshot to render to the specified sizes.
  ///
  /// - Parameter sizes: An array of sizes to render.
  /// - Returns: A trait that applies the specified sizes.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.sizes([.init(width: .fixed(300), height: .fixed(200))]))
  ///   func myView() -> some View { ... }
  /// }
  /// ```
  public static func sizes(
    _ sizes: [SizesSnapshotTrait.Size]
  ) -> Self {
    Self(sizes: sizes)
  }
}
