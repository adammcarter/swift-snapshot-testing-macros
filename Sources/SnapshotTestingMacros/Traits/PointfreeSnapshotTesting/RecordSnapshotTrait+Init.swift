import Foundation
import Testing

extension Testing.Trait where Self == RecordSnapshotTrait {
  /// Sets whether to record snapshots.
  ///
  /// - Parameter record: When `true`, all snapshots will be re-recorded (`.all`). When `false`,
  ///   they are strictly verified (`.never`): missing references fail the test and are never
  ///   written to disk.
  /// - Returns: A `RecordSnapshotTrait` configured with the specified recording mode.
  ///
  /// > Important: `.record(false)` diverges from swift-snapshot-testing's Bool convention, where
  /// > `record: false` maps to `.missing` (verify existing references but record missing ones).
  /// > This trait maps `false` to `.never` because it means "verified": a missing reference is a
  /// > failure, not an invitation to record. To bootstrap missing references while verifying
  /// > existing ones, use `.record(.missing)` — which is also pointfree's ultimate default when
  /// > no trait or ambient configuration is set.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.record(true))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func record(_ record: Bool) -> Self {
    Self(record: record ? .all : .never)
  }

  /// Sets the recording mode for snapshots.
  ///
  /// - Parameter record: The recording mode to use.
  /// - Returns: A `RecordSnapshotTrait` configured with the specified recording mode.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.record(.all))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func record(_ record: RecordSnapshotTrait.RecordKind) -> Self {
    Self(record: record)
  }

  /// Enables recording for snapshots.
  ///
  /// This is equivalent to `.record(true)`.
  ///
  /// - Returns: A `RecordSnapshotTrait` configured to record all snapshots.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.record)
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static var record: Self {
    record(true)
  }
}
