import Foundation
import Testing

extension Testing.Trait where Self == RecordSnapshotTrait {
  /// Sets whether to record snapshots.
  ///
  /// - Parameter record: When `true`, all snapshots will be re-recorded. When `false`, they are verified.
  /// - Returns: A `RecordSnapshotTrait` configured with the specified recording mode.
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
