import Foundation

extension SnapshotTrait where Self == PrecisionSnapshotTrait {
  /// Sets the required image precision (1.0 exact, 0.99 allows ~1% mismatch).
  ///
  /// - Parameter precision: A normalized precision value between `0` and `1`.
  /// - Returns: A trait that configures image comparison precision.
  public static func precision(_ precision: Float) -> Self {
    Self(precision: min(max(precision, 0), 1))
  }

  /// Adds image comparison tolerance for snapshot rendering drift.
  ///
  /// This is a convenience wrapper that converts tolerance into precision:
  /// `precision(1 - tolerance)`.
  ///
  /// The value is clamped to the range `0...1` where:
  /// - `0` requires a perfect match
  /// - `0.01` allows roughly 1% pixel mismatch
  ///
  /// - Parameter tolerance: A normalized tolerance value between `0` and `1`.
  /// - Returns: A trait that configures snapshot tolerance.
  public static func precision(tolerance: Float) -> Self {
    Self(precision: 1 - min(max(tolerance, 0), 1))
  }

  /// Requires an exact image match.
  public static var exact: Self {
    .precision(1)
  }
}
