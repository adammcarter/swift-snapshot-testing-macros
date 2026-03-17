import Foundation

extension SnapshotTrait where Self == StrategySnapshotTrait {
  /// Sets the snapshot strategy.
  ///
  /// - Parameter strategy: The strategy to use.
  /// - Returns: A trait that applies the strategy.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.strategy(.image))
  ///   func myView() -> some View { ... }
  /// }
  /// ```
  public static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy
  ) -> Self {
    Self(strategy: strategy)
  }
}
