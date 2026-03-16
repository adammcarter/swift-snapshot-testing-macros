import Foundation

extension SnapshotTrait where Self == StrategySnapshotTrait {
  /// Sets the snapshot strategy.
  ///
  /// - Parameter strategy: The strategy to use.
  /// - Returns: A trait that applies the strategy.
  public static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy
  ) -> Self {
    Self(strategy: strategy)
  }
}
