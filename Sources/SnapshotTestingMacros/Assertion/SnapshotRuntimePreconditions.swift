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
}
