import Foundation

extension SnapshotTrait where Self == RecordSnapshotTrait {
  /// Force the snapshot to re-record when `true`.
  public static func record(_ record: Bool) -> Self {
    Self(record: record ? .all : .never)
  }

  /// Control snapshot recording.
  public static func record(_ record: RecordSnapshotTrait.RecordKind) -> Self {
    Self(record: record)
  }

  /// Force the snapshot to re-record.
  public static var record: Self {
    record(true)
  }
}
