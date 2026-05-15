import Foundation

extension SnapshotTrait where Self == StrategySnapshotTrait {
  /// Sets the snapshot strategy.
  ///
  /// - Parameter strategy: The strategy to use.
  /// - Returns: A trait that applies the strategy.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.strategy(.image))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy
  ) -> Self {
    Self(strategy: strategy)
  }
}
