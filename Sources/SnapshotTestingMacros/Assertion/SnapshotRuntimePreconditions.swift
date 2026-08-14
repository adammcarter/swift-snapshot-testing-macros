import Testing

enum SnapshotRuntimePreconditions {
  static let activeTestTaskMessage =
    "#expectSnapshot(...) may only be used from the active Swift Testing test task. Detached tasks are unsupported."

  /// Validates that a snapshot assertion is running on the active Swift Testing test task.
  ///
  /// When no test context exists — `#expectSnapshot` called from a detached task, a GCD hop, or
  /// an XCTest-hosted method — this records a failure issue at the assertion's source location
  /// and returns `nil` so the caller can skip the assertion gracefully. The recorded issue
  /// surfaces as a run-level failure (there is no test to attribute it to), so the misuse can
  /// never silently pass, but it no longer aborts the whole test process the way the previous
  /// `preconditionFailure` did.
  @discardableResult
  static func requireActiveTestContext(
    _ currentTest: Test?,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    recordIssue: (Comment, SourceLocation) -> Void = { comment, sourceLocation in
      Issue.record(comment, sourceLocation: sourceLocation)
    }
  ) -> Test? {
    guard let currentTest else {
      recordIssue(
        Comment(rawValue: activeTestTaskMessage),
        SourceLocation(
          fileID: fileID.description,
          filePath: filePath.description,
          line: Int(line),
          column: Int(column)
        )
      )

      return nil
    }

    return currentTest
  }

  /// Unwraps a result smuggled out of a `MainActor.assumeIsolated` closure, recording a failure
  /// against the invoking assertion and falling back instead of trapping when it is missing.
  ///
  /// Nothing can currently leave such a box empty: `assumeIsolated` either runs its closure
  /// synchronously on the calling thread or traps before the unwrap is ever reached, and the
  /// AppKit values those closures store are non-optional. The unwrap exists only because the box
  /// must declare its storage optional. That makes this a defence-in-depth path, not a
  /// recoverable error — but a test library must degrade rather than abort: `preconditionFailure`
  /// here would take the whole suite down with a crash log instead of failing the one assertion
  /// whose render misbehaved.
  ///
  /// The caller supplies a `fallback` because the render strategies this guards are non-throwing
  /// closures that must return a value; the recorded failure, not the fallback artifact, is the
  /// diagnostic.
  static func requireMainActorResult<T>(
    _ value: T?,
    fallback: @autoclosure () -> T,
    message: String,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    recordFailure: (SnapshotFailure) -> Void = { $0.record() }
  ) -> T {
    guard let value else {
      recordFailure(
        SnapshotFailure(
          message: message,
          error: nil,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      )

      return fallback()
    }

    return value
  }
}
