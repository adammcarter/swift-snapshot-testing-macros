#if canImport(Testing)
import Testing
#else
import XCTest
#endif

/// One snapshot assertion failure, carried as a value so it can cross the adapter's
/// main-actor hop and be recorded on the calling test's task.
///
/// Recording must never happen inside the `DispatchQueue.main.sync` callout the adapter uses
/// for synchronous off-main assertions: a plain queue callout has no Swift task, so Swift
/// Testing's task-locals (`Test.current`, `Test.Case.current`, the `withKnownIssue` matcher)
/// all read nil there and the issue would surface as an orphaned run-level failure instead of
/// failing the invoking test.
struct SnapshotFailure: Sendable {
  /// The human-readable message for snapshot verification failures.
  let message: String?

  /// The underlying error for failures that are not snapshot verification failures.
  let error: (any Error)?

  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt

  /// Records this failure as an issue at the assertion's source location.
  ///
  /// Call this on the task that owns the assertion — the test's task — so the issue is
  /// attributed to the invoking test and `withKnownIssue` can match it.
  func record() {
    #if canImport(Testing)
    let comment = message.flatMap(Comment.init(rawValue:))
    let sourceLocation = SourceLocation(
      fileID: fileID.description,
      filePath: filePath.description,
      line: Int(line),
      column: Int(column)
    )

    if let error {
      Issue.record(
        error,
        comment,
        sourceLocation: sourceLocation
      )
    }
    else {
      Issue.record(
        comment,
        sourceLocation: sourceLocation
      )
    }
    #else
    XCTFail(message ?? error.map { "\($0)" } ?? "", file: filePath, line: line)
    #endif
  }
}
