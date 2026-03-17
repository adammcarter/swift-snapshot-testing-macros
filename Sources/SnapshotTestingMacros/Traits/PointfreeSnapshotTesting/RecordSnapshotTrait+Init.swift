import Foundation

extension SnapshotTrait where Self == RecordSnapshotTrait {
  /// Sets whether to record snapshots.
  ///
  /// - Parameter record: When `true`, all snapshots will be re-recorded. When `false`, they are verified.
  /// - Returns: A `RecordSnapshotTrait` configured with the specified recording mode.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.record(true))
  ///   func myView() -> some View { ... }
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
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.record(.all))
  ///   func myView() -> some View { ... }
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
  /// @SnapshotSuite
  /// struct MySnapshotSuite {
  ///
  ///   @SnapshotTest(.record)
  ///   func myView() -> some View { ... }
  /// }
  /// ```
  public static var record: Self {
    record(true)
  }
}
