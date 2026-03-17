import Foundation

extension SizesSnapshotTrait {
  /// Represents a device for snapshot sizing.
  ///
  /// Device dimensions mirror Point-Free SnapshotTesting `ViewImageConfig` defaults
  /// (portrait for iPhone models, landscape/full split for iPad models).
  public enum Device: CaseIterable, Sendable, CustomDebugStringConvertible {
    case iPhoneSE
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhoneXsMax
    case iPhoneXr
    case iPhone12
    case iPhone12Pro
    case iPhone12ProMax
    case iPhone13
    case iPhone13Mini
    case iPhone13Pro
    case iPhone13ProMax
    case iPadMini
    case iPad9_7  // swiftlint:disable:this identifier_name
    case iPad10_2  // swiftlint:disable:this identifier_name
    case iPadPro10_5  // swiftlint:disable:this identifier_name
    case iPadPro11
    case iPadPro12_9  // swiftlint:disable:this identifier_name

    private struct Metadata {
      let width: Double
      let height: Double
      let scale: Double
      let debugDescription: String
    }

    private var metadata: Metadata {
      switch self {
        case .iPhoneSE: .init(width: 320, height: 568, scale: 2, debugDescription: "iPhoneSE")
        case .iPhone8: .init(width: 375, height: 667, scale: 2, debugDescription: "iPhone8")
        case .iPhone8Plus: .init(width: 414, height: 736, scale: 3, debugDescription: "iPhone8Plus")
        case .iPhoneX: .init(width: 375, height: 812, scale: 3, debugDescription: "iPhoneX")
        case .iPhoneXsMax: .init(width: 414, height: 896, scale: 3, debugDescription: "iPhoneXsMax")
        case .iPhoneXr: .init(width: 414, height: 896, scale: 2, debugDescription: "iPhoneXr")
        case .iPhone12: .init(width: 390, height: 844, scale: 3, debugDescription: "iPhone12")
        case .iPhone12Pro: .init(width: 390, height: 844, scale: 3, debugDescription: "iPhone12Pro")
        case .iPhone12ProMax: .init(width: 428, height: 926, scale: 3, debugDescription: "iPhone12ProMax")
        case .iPhone13: .init(width: 390, height: 844, scale: 3, debugDescription: "iPhone13")
        case .iPhone13Mini: .init(width: 375, height: 812, scale: 3, debugDescription: "iPhone13Mini")
        case .iPhone13Pro: .init(width: 390, height: 844, scale: 3, debugDescription: "iPhone13Pro")
        case .iPhone13ProMax: .init(width: 428, height: 926, scale: 3, debugDescription: "iPhone13ProMax")
        case .iPadMini: .init(width: 1024, height: 768, scale: 2, debugDescription: "iPadMini")
        case .iPad9_7: .init(width: 1024, height: 768, scale: 2, debugDescription: "iPad9_7")
        case .iPad10_2: .init(width: 1080, height: 810, scale: 2, debugDescription: "iPad10_2")
        case .iPadPro10_5: .init(width: 1112, height: 834, scale: 2, debugDescription: "iPadPro10_5")
        case .iPadPro11: .init(width: 1194, height: 834, scale: 2, debugDescription: "iPadPro11")
        case .iPadPro12_9: .init(width: 1366, height: 1024, scale: 2, debugDescription: "iPadPro12_9")
      }
    }

    /// The width of the device in points.
    public var width: Double {
      metadata.width
    }

    /// The height of the device in points.
    public var height: Double {
      metadata.height
    }

    /// The display scale of the device (e.g., 2.0 or 3.0).
    public var scale: Double {
      metadata.scale
    }

    public var debugDescription: String {
      metadata.debugDescription
    }
  }
}
