import Foundation
import SnapshotTesting
import Testing

public struct DiffToolSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let diffTool: DiffTool

  @TaskLocal static var current = DiffTool.default

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
