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

/// Runs the generator's assertions and returns the failures instead of recording them.
///
/// The native `#expectSnapshot` adapter calls this inside its main-actor hop and records the
/// returned failures after hopping back to the test's task, where `Test.current` and the
/// `withKnownIssue` matcher are intact.
@MainActor
func collectSnapshotFailuresSync(
  with viewGenerator: some SnapshotViewGenerating
) throws -> [SnapshotFailure] {
  let requests = try AssertionRequestGenerator(viewGenerator: viewGenerator).generateRequestsSync()

  return Asserter().collectFailuresSync(from: requests)
}
