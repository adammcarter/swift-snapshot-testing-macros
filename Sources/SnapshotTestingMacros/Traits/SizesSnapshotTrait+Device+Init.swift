import Foundation
import Testing

extension Testing.Trait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the size of the specified devices.
  ///
  /// - Parameters:
  ///   - devices: The devices to simulate.
  ///   - sizingOption: How to fit the content within the device dimensions. Defaults to `.widthAndHeight`.
  /// - Returns: A trait that applies the device sizes.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.sizes(devices:
  ///     .iPhoneX,
  ///     .iPhone12
  ///   ))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
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
