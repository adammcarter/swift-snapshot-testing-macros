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
  /// Wraps every attempt of the test body in a fresh ``SnapshotAttemptToken`` scope so all
  /// snapshot assertions within the attempt share one execution context, before delegating to
  /// the trait's own scope.
  public func provideScope(
    for _: Test,
    testCase _: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    try await SnapshotAttemptToken.withAttemptScope {
      try await provideScope(performing: function)
    }
  }
}
