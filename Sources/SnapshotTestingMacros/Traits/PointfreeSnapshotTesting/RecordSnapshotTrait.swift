import Foundation
import SnapshotTesting
import Testing

/// A trait that configures the recording mode for snapshots.
public struct RecordSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let record: RecordKind

  /// The record mode explicitly set by a `.record` trait, or `nil` when no trait is present.
  ///
  /// `nil` means "unset": the asserter passes it through to pointfree's
  /// `withSnapshotTesting(record:)`, which then falls back to ambient pointfree-native
  /// configuration — a consumer's own `withSnapshotTesting`, pointfree's `.snapshots` trait,
  /// or the `SNAPSHOT_TESTING_RECORD` environment variable — before pointfree's default.
  /// A non-nil default here would clobber all of those sources.
  @TaskLocal
  static var current: RecordKind?

  public var debugDescription: String {
    "record: \(record)"
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await RecordSnapshotTrait.$current.withValue(record) {
      try await function()
    }
  }

  public typealias RecordKind = SnapshotTesting.SnapshotTestingConfiguration.Record
}
