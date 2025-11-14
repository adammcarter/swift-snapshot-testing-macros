import Foundation

struct AssertionRequestContext {
  let name: String
  let makeSnapshotView: @MainActor () async throws -> SnapshotViewController
  let snapshotDirectory: String
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt
}
