import Foundation
import Testing

/// A trait that provides a scope for a snapshot test execution.
///
/// This protocol allows traits to wrap the execution of a test or suite, enabling setup and teardown logic,
/// or modifying the environment (e.g., using `@TaskLocal` values).
public protocol SnapshotTestScoping: Testing.Trait, Testing.TestScoping {
  /// Wraps the execution of the test function.
  ///
  /// - Parameter function: The test function to execute.
  func provideScope(
    performing function: () async throws -> Void
  ) async throws
}

extension SnapshotTestScoping {
  /// Wraps every attempt of a test case in a fresh ``SnapshotAttemptToken`` scope so all
  /// snapshot assertions within the attempt share one execution context, before delegating to
  /// the trait's own scope.
  ///
  /// The token is bound only for test-case invocations (`testCase != nil`). A suite-level
  /// invocation wraps ALL of the suite's tests in one call — binding there would make every
  /// test in the suite share a single execution context, leaking artifact names across tests.
  public func provideScope(
    for _: Test,
    testCase: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    guard testCase != nil else {
      try await provideScope(performing: function)
      return
    }

    try await SnapshotAttemptToken.withAttemptScope {
      try await provideScope(performing: function)
    }
  }
}
