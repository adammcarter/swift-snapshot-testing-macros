import Foundation
import Testing

/// A trait that provides a scope for a snapshot test execution.
///
/// This protocol allows traits to wrap the execution of a test or suite, enabling setup and teardown logic,
/// or modifying the environment (e.g., using `@TaskLocal` values).
public protocol SnapshotTestScoping: Testing.Trait {
  /// Wraps the execution of the test function.
  ///
  /// - Parameter function: The test function to execute.
  func provideScope(
    performing function: () async throws -> Void
  ) async throws
}
