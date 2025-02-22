import Foundation

public struct RecordSnapshotTrait: SnapshotTrait {
  let record: Bool

  public var debugDescription: String {
    "record: \(record)"
  }
}
