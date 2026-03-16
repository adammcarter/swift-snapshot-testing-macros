import Foundation

extension SizesSnapshotTrait {
  /// Represents a dimension length for a snapshot.
  public enum Length: Sendable, CustomDebugStringConvertible, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    /// A fixed length in points.
    case fixed(Double)
    /// The minimum size required to fit the content.
    case minimum
    #warning(
      "TODO: Add case for .minimum(.intrinsicContentSize | .preferredContentSize) so VCs can explicitly size based on auto layout or preferred size. .minimum will still be available and just convert under the hood to be minimum(.intrinsicContentSize)"
    )

    /// Creates a fixed length from an integer.
    public static func fixed(_ int: Int) -> Self {
      .init(integerLiteral: int)
    }

    /// Creates a fixed length from a floating-point value.
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
