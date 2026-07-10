import Foundation
import Testing

/// A per-attempt identity token that owns the ``SnapshotExecutionContext`` for one execution
/// (attempt) of a test body.
///
/// Every ``SnapshotTestScoping`` trait binds a fresh token as a task-local around the test
/// body, once per attempt:
///
/// - All `#expectSnapshot` calls within the attempt — including calls made from helper
///   functions and from child tasks spawned by the test body, which inherit the task-local —
///   resolve the same token and therefore share one execution context, keeping unnamed
///   artifact suffixes ("-2", "-3", …) and `.N` reference-file identifiers stable and
///   deterministic in execution order. Concurrent unnamed assertions have no deterministic
///   execution order and must provide explicit assertion or configuration identity.
/// - A new attempt (test retry or repetition) enters the trait's scope again and receives a
///   fresh token, so its first unnamed assertion resolves the unsuffixed base name and the
///   `.1` reference identifier again.
/// - Because the token is a class instance, its identity cannot be recycled while anything
///   still references it — unlike raw current-task pointer bits, which the allocator reuses
///   for new tasks almost immediately.
/// - The context is stored on the token itself, so its lifetime is exactly the attempt's:
///   there is no global cache to evict or leak.
final class SnapshotAttemptToken: @unchecked Sendable {
  @TaskLocal
  static var current: SnapshotAttemptToken?

  private let lock = NSLock()
  private var context: SnapshotExecutionContext?

  /// Whether this attempt belongs to a parameterized case. Swift Testing exposes this fact
  /// publicly even though its shipped Apple module does not expose case argument values.
  private let isParameterizedCase: Bool

  init(isParameterizedCase: Bool = false) {
    self.isParameterizedCase = isParameterizedCase
  }

  /// Returns the attempt's execution context, creating it on first use.
  func executionContext(function: StaticString) -> SnapshotExecutionContext {
    lock.withLock {
      if let context {
        return context
      }

      let created = SnapshotExecutionContext(
        function: function,
        isParameterizedCase: isParameterizedCase
      )
      context = created
      return created
    }
  }

  /// Runs `work` with an attempt token bound as a task-local.
  ///
  /// Nested snapshot trait scopes (for example a suite trait and a test trait applied to the
  /// same test) belong to the same attempt, so an already-bound token is kept rather than
  /// replaced: every assertion in the attempt shares one execution context.
  ///
  /// `testCase` is the current case Swift Testing passes to `provideScope`. Only its public
  /// `isParameterized` fact is retained; unnamed bare assertions in parameterized tests must use
  /// an explicit identity because the shipped Apple module exposes no supported argument values.
  static func withAttemptScope<T>(
    for testCase: Test.Case?,
    perform work: () async throws -> T
  ) async rethrows -> T {
    if current != nil {
      return try await work()
    }

    let token = SnapshotAttemptToken(isParameterizedCase: testCase?.isParameterized == true)
    return try await $current.withValue(token) {
      try await work()
    }
  }
}
