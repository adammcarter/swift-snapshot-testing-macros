import Foundation

@available(*, message: "This is an implementation detail. Do not call this function directly.")
@MainActor
public func assertSnapshot(with viewGenerator: some SnapshotViewGenerating) async throws {
  try assertSnapshotSync(with: await resolvedSyncViewGenerator(from: viewGenerator))
}

/// Awaits an async generator's `makeValue` once and rebuilds it as a synchronous generator so
/// the sync assertion pipeline can run against the resolved value. Synchronous generators pass
/// through untouched. This is what keeps legacy async `@SnapshotTest` functions (and suites
/// with async inits) working now that assertions themselves run synchronously on the main
/// actor.
@MainActor
func resolvedSyncViewGenerator<G: SnapshotViewGenerating>(
  from viewGenerator: G
) async throws -> any SnapshotViewGenerating {
  guard let makeViewControllerAsync = viewGenerator.makeViewControllerAsync else {
    return viewGenerator
  }

  let viewController = try await makeViewControllerAsync(viewGenerator.configuration.value)

  return SnapshotViewGenerator<G.ConfigurationValue>(
    displayName: viewGenerator.displayName,
    configuration: viewGenerator.configuration,
    makeValue: { _ in viewController },
    fileID: viewGenerator.fileID,
    filePath: viewGenerator.filePath,
    line: viewGenerator.line,
    column: viewGenerator.column
  )
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
