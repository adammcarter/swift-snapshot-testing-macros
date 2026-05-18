import Foundation

@available(*, message: "This is an implementation detail. Do not call this function directly.")
@MainActor
public func assertSnapshot(with viewGenerator: some SnapshotViewGenerating) async throws {
  try assertSnapshotSync(with: viewGenerator)
}

@MainActor
func assertSnapshotSync(with viewGenerator: some SnapshotViewGenerating) throws {
  let requests = try AssertionRequestGenerator(viewGenerator: viewGenerator).generateRequestsSync()

  Asserter().assertSnapshotsSync(from: requests)
}
