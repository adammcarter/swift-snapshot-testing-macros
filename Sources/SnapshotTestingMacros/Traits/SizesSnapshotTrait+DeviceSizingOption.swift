import Foundation

extension SizesSnapshotTrait {
  /// Options for how to fit the content within the device dimensions.
  public enum DeviceSizingOption: CaseIterable, Sendable, CustomDebugStringConvertible {
    /// Use both the device width and height.
    case widthAndHeight
    /// Use the device width but allow the height to fit the content (minimum height).
    case widthButMinimumHeight
    /// Use the device height but allow the width to fit the content (minimum width).
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
