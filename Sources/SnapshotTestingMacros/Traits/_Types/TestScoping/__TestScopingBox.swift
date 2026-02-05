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
    testCase _: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    try await snapshotTestScoping.provideScope(performing: function)
  }
}
