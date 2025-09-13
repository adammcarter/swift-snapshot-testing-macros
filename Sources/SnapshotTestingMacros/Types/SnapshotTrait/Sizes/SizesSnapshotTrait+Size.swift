import Foundation

extension SizesSnapshotTrait {
  public struct Size: Sendable, CustomDebugStringConvertible {
    let width: SizesSnapshotTrait.Length
    let height: SizesSnapshotTrait.Length
    let scale: Double

    public let displayName: String
    public let debugDescription: String
    public let testNameDescription: String

    public init(
      width: SizesSnapshotTrait.Length,
      height: SizesSnapshotTrait.Length,
      scale: Double = defaultScale
    ) {
      self.width = width
      self.height = height
      self.scale = scale
      self.displayName = "size"
      self.debugDescription = "width: \(width), height: \(height), scale: \(scale)"

      let description =
        switch (width, height) {
          case (.fixed, .fixed): "fixed size"
          case (.fixed, .minimum): "min height"
          case (.minimum, .fixed): "min width"
          case (.minimum, .minimum): "min size"
        }

      self.testNameDescription = description.replacingOccurrences(of: " ", with: "-")
    }

    init(
      width: SizesSnapshotTrait.Length,
      height: SizesSnapshotTrait.Length,
      scale: Double = defaultScale,
      displayName: String,
      debugDescription: String,
      testNameDescription: String
    ) {
      self.width = width
      self.height = height
      self.scale = scale
      self.displayName = displayName
      self.debugDescription = debugDescription
      self.testNameDescription = testNameDescription
    }

    init(
      device: SizesSnapshotTrait.Device,
      sizingOption: SizesSnapshotTrait.DeviceSizingOption
    ) {
      let (width, height): (SizesSnapshotTrait.Length, SizesSnapshotTrait.Length) =
        switch sizingOption {
          case .widthAndHeight:
            (
              .fixed(device.width),
              .fixed(device.height)
            )

          case .widthButMinimumHeight:
            (
              .fixed(device.width),
              .minimum
            )

          case .heightButMinimumWidth:
            (
              .minimum,
              .fixed(device.height)
            )
        }

      let testNameDescription = [
        device.debugDescription,
        sizingOption.testNameDescription,
      ]
      .compactMap { $0 }
      .joined(separator: "-")

      self = Self(
        width: width,
        height: height,
        scale: device.scale,
        displayName: "device",
        debugDescription: device.debugDescription,
        testNameDescription: testNameDescription
      )
    }
  }
}

@usableFromInline let defaultScale = 1.0
