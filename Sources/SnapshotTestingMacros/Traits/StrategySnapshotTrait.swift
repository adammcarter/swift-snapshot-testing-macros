import Foundation
import Testing

public struct StrategySnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let strategy: Strategy

  @TaskLocal static var current = Strategy.image

  public var debugDescription: String {
    "strategy: \(strategy)"
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await StrategySnapshotTrait.$current.withValue(strategy) {
      try await function()
    }
  }

  public enum Strategy: Sendable {
    case image
    case recursiveDescription
  }
}
