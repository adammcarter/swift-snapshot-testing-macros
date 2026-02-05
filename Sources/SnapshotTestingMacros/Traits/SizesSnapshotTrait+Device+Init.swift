import Foundation

extension SnapshotTrait where Self == SizesSnapshotTrait {
  /// Allows the snapshot to render to the size of the specified devices.
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
