import Foundation
import Testing

/// A trait that configures the snapshotting strategy.
///
/// Use this trait to switch between image-based comparison and recursive description comparison.
public struct StrategySnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let strategy: Strategy

  @TaskLocal
  static var current = Strategy.image

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

  /// The type of snapshot strategy to use.
  public enum Strategy: Sendable {
    /// Compare rendered images.
    case image
    /// Compare recursive view description (debug output).
    case recursiveDescription
  }
}
