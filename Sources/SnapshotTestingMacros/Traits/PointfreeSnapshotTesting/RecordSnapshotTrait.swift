import Foundation
import SnapshotTesting
import Testing

#warning("TODO: We can add unit tests to these snapshot traits now")
public struct RecordSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let record: RecordKind

  @TaskLocal static var current = RecordKind.missing

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
