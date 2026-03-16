import Foundation

extension SizesSnapshotTrait {
  /// Represents a device for snapshot sizing.
  public enum Device: CaseIterable, Sendable, CustomDebugStringConvertible {
    case iPhoneX
    case iPhone12
    case iPadPro11
    case iPadPro12_9  // swiftlint:disable:this identifier_name

    /// The width of the device in points.
    public var width: Double {
      switch self {
        case .iPhoneX: 375
        case .iPhone12: 390
        case .iPadPro11: 1194
        case .iPadPro12_9: 1366
      }
    }

    /// The height of the device in points.
    public var height: Double {
      switch self {
        case .iPhoneX: 812
        case .iPhone12: 844
        case .iPadPro11: 834
        case .iPadPro12_9: 1024
      }
    }

    /// The display scale of the device (e.g., 2.0 or 3.0).
    public var scale: Double {
      switch self {
        case .iPhoneX,
          .iPhone12:
          3

        case .iPadPro11,
          .iPadPro12_9:
          2
      }
    }

    public var debugDescription: String {
      switch self {
        case .iPhoneX: "iPhoneX"
        case .iPhone12: "iPhone12"
        case .iPadPro11: "iPadPro11"
        case .iPadPro12_9: "iPadPro12_9"
      }
    }
  }
}
