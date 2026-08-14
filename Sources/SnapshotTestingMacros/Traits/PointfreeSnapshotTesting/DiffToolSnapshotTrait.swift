import Foundation
import SnapshotTesting
import Testing

/// A trait that configures the diff tool used for snapshot failures.
public struct DiffToolSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let diffTool: DiffTool

  /// The diff tool explicitly set by a `.diffTool` trait, or `nil` when no trait is present.
  ///
  /// `nil` means "unset": the asserter passes it through to pointfree's
  /// `withSnapshotTesting(diffTool:)`, which then falls back to ambient pointfree-native
  /// configuration (a consumer's own `withSnapshotTesting` or pointfree's `.snapshots` trait)
  /// before pointfree's default. A non-nil default here would clobber those sources.
  @TaskLocal
  static var current: DiffTool?

  public var debugDescription: String {
    "diffTool: \(diffTool)"
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await DiffToolSnapshotTrait.$current.withValue(diffTool) {
      try await function()
    }
  }

  public typealias DiffTool = SnapshotTesting.SnapshotTestingConfiguration.DiffTool
}
