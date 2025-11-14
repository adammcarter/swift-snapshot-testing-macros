import Foundation
import SnapshotTesting

@MainActor
protocol AssertionRequesting: Sendable {
  associatedtype Format

  var view: SnapshotViewController { get }
  var snapshotting: Snapshotting<SnapshotViewController, Format> { get }
  var snapshotDirectory: String? { get }
  var fileID: StaticString { get }
  var filePath: StaticString { get }
  var testName: String { get }
  var line: UInt { get }
  var column: UInt { get }
}

struct AssertionRequest<Format>: AssertionRequesting {
  let view: SnapshotViewController
  let snapshotting: Snapshotting<SnapshotViewController, Format>
  let snapshotDirectory: String?
  let testName: String
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt
}
