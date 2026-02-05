import Foundation

@available(*, message: "This is an implementation detail. Do not call this function directly.")
@MainActor
public func assertSnapshot(with viewGenerator: some SnapshotViewGenerating) async throws {
  let requests = try await AssertionRequestGenerator(viewGenerator: viewGenerator).generateRequests()

  Asserter().assertSnapshots(from: requests)
}
