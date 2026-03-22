import Foundation
import Testing

/// A trait that configures image comparison precision for snapshot matching.
public struct PrecisionSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let precision: Float

  init(precision: Float) {
    self.precision = min(max(precision, 0), 1)
  }

  @TaskLocal
  static var current: Float = 1

  public var debugDescription: String {
    "precision: \(precision)"
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await PrecisionSnapshotTrait.$current.withValue(precision) {
      try await function()
    }
  }
}
