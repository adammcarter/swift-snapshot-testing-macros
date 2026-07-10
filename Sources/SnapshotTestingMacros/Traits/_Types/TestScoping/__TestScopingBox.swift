import Testing

@available(*, message: "This is an implementation detail. Do not use this type directly.")
// swiftlint:disable:next type_name
public struct __TestScopingBox: Testing.TestScoping {
  private let snapshotTestScoping: any SnapshotTestScoping

  init(_ snapshotTestScoping: any SnapshotTestScoping) {
    self.snapshotTestScoping = snapshotTestScoping
  }

  public func provideScope(
    for _: Test,
    testCase: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    // Suite-level invocations (`testCase == nil`) wrap all of a suite's tests in one call;
    // binding the attempt token there would share one execution context across every test.
    guard testCase != nil else {
      try await snapshotTestScoping.provideScope(performing: function)
      return
    }

    try await SnapshotAttemptToken.withAttemptScope {
      try await snapshotTestScoping.provideScope(performing: function)
    }
  }
}
