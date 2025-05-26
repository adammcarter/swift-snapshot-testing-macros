import Testing

// Set up * without * configuration ...
public struct SnapshotSetUpTrait: /*TestTrait, TestScoping, */SnapshotTrait {
  public typealias SetUp = @Sendable () async throws -> Void

  let setUp: SetUp

  public var debugDescription: String {
    "SnapshotSetUpTrait"
  }

  public init(setUp: @escaping SetUp) {
    self.setUp = setUp
  }

//  public func provideScope(
//    for test: Test,
//    testCase: Test.Case?,
//    performing function: @Sendable () async throws -> Void
//  ) async throws {
//    try await setUp()
//
//    try await function()
//  }
}

public struct SnapshotConfigurationSetUpTrait<T: Sendable>: /*TestTrait, TestScoping, */SnapshotTrait {
  public typealias SetUp = @Sendable (SnapshotConfiguration<T>) async throws -> Void

  let setUp: SetUp

  public var debugDescription: String {
    "SnapshotSetUpTrait"
  }

  public init(setUp: @escaping SetUp) {
    self.setUp = setUp
  }

//  public func provideScope(
//    for test: Test,
//    testCase: Test.Case?,
//    performing function: @Sendable () async throws -> Void
//  ) async throws {
//    try await setUp(configuration)
//
//    try await function()
//  }
}
