import Foundation

extension SnapshotTrait where Self == StrategySnapshotTrait {
  public static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy
  ) -> Self {
    Self(strategy: strategy)
  }
}
