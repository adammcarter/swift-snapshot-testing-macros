import Foundation

extension SizesSnapshotTrait {
  public enum Device: CaseIterable, Sendable, CustomDebugStringConvertible {
    case iPhoneX
    case iPhone12
    case iPadPro11
    case iPadPro12_9  // swiftlint:disable:this identifier_name

    public var width: Double {
      switch self {
        case .iPhoneX: 375
        case .iPhone12: 390
        case .iPadPro11: 1194
        case .iPadPro12_9: 1366
      }
    }

    public var height: Double {
      switch self {
        case .iPhoneX: 812
        case .iPhone12: 844
        case .iPadPro11: 834
        case .iPadPro12_9: 1024
      }
    }

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
