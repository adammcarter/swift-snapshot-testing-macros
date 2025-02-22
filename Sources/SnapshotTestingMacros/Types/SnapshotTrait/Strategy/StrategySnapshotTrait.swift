import Foundation

public struct StrategySnapshotTrait: SnapshotTrait {
  let strategy: Strategy

  public var debugDescription: String {
    "strategy: \(strategy)"
  }

  public enum Strategy {
    case image
    case recursiveDescription
  }
}
