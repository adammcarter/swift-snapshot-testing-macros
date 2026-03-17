import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the size of the specified devices.
  ///
  /// - Parameters:
  ///   - devices: The devices to simulate.
  ///   - sizingOption: How to fit the content within the device dimensions. Defaults to `.widthAndHeight`.
  /// - Returns: A trait that applies the device sizes.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.sizes(devices:
  ///     .iPhoneX,
  ///     .iPhone12
  ///   ))
  ///   func myView() -> some View { ... }
  /// }
  /// ```
  public static func sizes(
    devices: SizesSnapshotTrait.Device...,
    fitting sizingOption: SizesSnapshotTrait.DeviceSizingOption = .widthAndHeight
  ) -> Self {
    Self(
      sizes: devices.map {
        .init(device: $0, sizingOption: sizingOption)
      }
    )
  }
}
