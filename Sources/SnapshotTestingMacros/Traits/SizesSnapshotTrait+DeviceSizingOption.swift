import Foundation

extension SizesSnapshotTrait {
  public enum DeviceSizingOption: CaseIterable, Sendable, CustomDebugStringConvertible {
    case widthAndHeight
    case widthButMinimumHeight
    case heightButMinimumWidth

    public var debugDescription: String {
      switch self {
        case .widthAndHeight: "widthAndHeight"
        case .widthButMinimumHeight: "widthButMinimumHeight"
        case .heightButMinimumWidth: "heightButMinimumWidth"
      }
    }

    public var testNameDescription: String? {
      switch self {
        case .widthAndHeight: nil
        case .widthButMinimumHeight: "min-height"
        case .heightButMinimumWidth: "min-width"
      }
    }
  }
}
