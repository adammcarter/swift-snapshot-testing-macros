import Foundation

extension SizesSnapshotTrait {
  public enum Length: Sendable, CustomDebugStringConvertible, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    case fixed(Double)
    case minimum

    public static func fixed(_ int: Int) -> Self {
      .init(integerLiteral: int)
    }

    public static func fixed(_ float: CGFloat) -> Self {
      .init(floatLiteral: float)
    }

    public var debugDescription: String {
      switch self {
        case .fixed(let value): "\(value)"
        case .minimum: "minimum"
      }
    }

    public init(floatLiteral value: Double) {
      self = .fixed(value)
    }

    public init(integerLiteral value: Int) {
      self.init(floatLiteral: Double(value))
    }
  }
}
