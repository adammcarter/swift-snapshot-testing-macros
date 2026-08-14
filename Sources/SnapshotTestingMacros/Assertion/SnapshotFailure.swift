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

  /// The mismatch's reference and newly-taken images, attached alongside the issue.
  ///
  /// `nil` whenever there was nothing to compare — a missing reference on first record — or
  /// when the failure was not a snapshot verification failure at all.
  var artifacts: SnapshotFailureArtifacts?

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

    /*
     Attached from here — the test's task — for the same reason the issue is: an attachment
     recorded inside the adapter's main-queue callout has no task to attribute it to.

     Swift Testing gained `Attachment` in 6.2, and this package supports toolchains that predate
     it. Older toolchains keep the message, which already carries the reference and failure
     paths, so the diagnostic degrades rather than disappearing.
     */
    #if compiler(>=6.2)
    for attachment in artifacts?.attachments() ?? [] {
      Attachment.record(
        Attachment(attachment.data, named: attachment.name, sourceLocation: sourceLocation),
        sourceLocation: sourceLocation
      )
    }
    #endif
    #else
    XCTFail(message ?? error.map { "\($0)" } ?? "", file: filePath, line: line)
    #endif
  }
}
