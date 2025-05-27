import Foundation

// TODO: Conform both to Sendable?

public protocol SnapshotTrait: CustomDebugStringConvertible {}

public protocol SnapshotScopeProviding {
  // TODO: Probably shouldn't be a main actor ??
  @MainActor
  func provideScope<Value: Sendable>(
    // TODO: Add these types ??
//    for test: Test,
//    testCase: Test.Case?,
    configuration: SnapshotConfiguration<Value>?,
    performing function: @Sendable () async throws -> Void
  ) async throws
}
