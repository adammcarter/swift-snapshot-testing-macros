import Testing

/// This is an implementation detail of the legacy trait-box macro expansion. Do not use this
/// type directly. It is `public` only for macro-generated code and is hidden from documentation.
@_documentation(visibility: private)
// swiftlint:disable:next type_name
public struct __TestScopingBox: Testing.TestScoping {
  private let snapshotTestScoping: any SnapshotTestScoping

  init(_ snapshotTestScoping: any SnapshotTestScoping) {
    self.snapshotTestScoping = snapshotTestScoping
  }

  /// Forwards the wrapped trait's comments so boxing does not strip them.
  public var comments: [Comment] {
    snapshotTestScoping.comments
  }

  /// Forwards the wrapped trait's preparation so boxing does not strip it.
  public func prepare(for test: Test) async throws {
    try await snapshotTestScoping.prepare(for: test)
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

    try await SnapshotAttemptToken.withAttemptScope(for: testCase) {
      try await snapshotTestScoping.provideScope(performing: function)
    }
  }
}
