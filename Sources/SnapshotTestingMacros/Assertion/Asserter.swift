import Foundation
import SnapshotTesting

/// Top level asserter - allows us to change the base and internals without updating the top level call site
struct Asserter {

  @MainActor
  func assertSnapshotsSync(from requests: [any AssertionRequesting]) {
    SnapshotTesting.withSnapshotTesting(
      record: RecordSnapshotTrait.current,
      diffTool: DiffToolSnapshotTrait.current
    ) {
      Self.performAssertions(
        using: IssueRecordingAsserter(base: PointfreeAsserter()),
        requests: requests
      )
    }
  }

  func assertSnapshots(from requests: [any AssertionRequesting]) async throws {
    await MainActor.run {
      assertSnapshotsSync(from: requests)
    }
  }

  @MainActor
  private static func performAssertions(
    using asserter: IssueRecordingAsserter,
    requests: [any AssertionRequesting]
  ) {
    for request in requests {
      asserter.assertSnapshot(request)
    }
  }
}

// MARK: - Asserters

@MainActor
protocol SnapshotAsserting {

  func assertSnapshot(_ request: any AssertionRequesting) throws
}

// MARK: - IssueRecordingAsserter

#if canImport(Testing)
import Testing
#endif

/// Record issues on throw
struct IssueRecordingAsserter: SnapshotAsserting {
  let base: any SnapshotAsserting
  var recordIssue: ((_ message: String?, _ error: Error?, _ fileID: StaticString, _ filePath: StaticString, _ line: UInt, _ column: UInt) -> Void)?

  func assertSnapshot(_ request: any AssertionRequesting) {
    do {
      try base.assertSnapshot(request)
    }
    catch let error as SnapshotError {
      if let recordIssue {
        recordIssue(error.message, nil, request.fileID, request.filePath, request.line, request.column)
      }
      else {
        recordIssue(
          message: error.message,
          fileID: request.fileID,
          filePath: request.filePath,
          line: request.line,
          column: request.column
        )
      }
    }
    catch {
      if let recordIssue {
        recordIssue(nil, error, request.fileID, request.filePath, request.line, request.column)
      }
      else {
        recordIssue(
          error: error,
          fileID: request.fileID,
          filePath: request.filePath,
          line: request.line,
          column: request.column
        )
      }
    }
  }

  private func recordIssue(
    error: Error? = nil,
    message: @autoclosure (() -> String?) = nil,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    #if canImport(Testing)
    let comment = message().flatMap(Comment.init(rawValue:))
    let sourceLocation = SourceLocation(
      fileID: fileID.description,
      filePath: filePath.description,
      line: Int(line),
      column: Int(column)
    )

    if Test.current != nil {
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
    }
    else {
      Issue.record(
        comment,
        sourceLocation: sourceLocation
      )
    }
    #else
    XCTFail(message(), file: filePath, line: line)
    #endif
  }
}

// MARK: - PointfreeAsserter

/// Underlying Pointfree assertion
private struct PointfreeAsserter: SnapshotAsserting {

  func assertSnapshot(_ request: any AssertionRequesting) throws {
    try verifySnapshot(request: request)
  }

  #warning("TODO: Allow timeout customisation via new trait")

  private func verifySnapshot(request: some AssertionRequesting) throws {
    let message = SnapshotTesting.verifySnapshot(
      of: request.view,
      as: request.snapshotting,
      named: referenceIdentifier(for: request),
      snapshotDirectory: request.snapshotDirectory,
      timeout: 5,
      fileID: request.fileID,
      file: request.filePath,
      testName: request.testName,
      line: request.line,
      column: request.column
    )

    if let message {
      throw SnapshotError(message: message)
    }
  }

  /// Resolves the `.N` reference-file identifier from the attempt-scoped execution context.
  ///
  /// With `named: nil`, pointfree derives the identifier from a counter that is process-global
  /// on the native `#expectSnapshot` path: the task-local counter is never bound (only
  /// pointfree's `.snapshots` trait binds it, which native usage does not apply), and off-main
  /// assertions lose `Test.current` across the main-queue hop and fall back to a global that
  /// only an XCTest observer resets. Either way the counter keeps growing across attempts and
  /// tests, so repetitions look for `name.2.png` that was never recorded and parallel
  /// same-named tests are assigned `.N` suffixes by scheduling order.
  ///
  /// Counting within the attempt's ``SnapshotExecutionContext`` instead — the context the
  /// adapter re-binds across the main-queue hop — reproduces the legacy behaviour, where the
  /// auto-applied `.pointfreeSnapshots` trait reset pointfree's counter per test: every
  /// attempt restarts at `.1`, and same-key assertions within one attempt count up
  /// deterministically.
  ///
  /// Without a bound context — the deprecated `@SnapshotSuite` path, which enters through
  /// `assertSnapshot(with:)` and does apply `.pointfreeSnapshots` — this returns `nil` so
  /// pointfree's own per-test counter keeps assigning identifiers exactly as before.
  private func referenceIdentifier(for request: some AssertionRequesting) -> String? {
    guard let context = TaskLocalSnapshotExecutionContext.current else {
      return nil
    }

    return context.nextReferenceIdentifier(forKey: Self.referenceCounterKey(for: request))
  }

  /// Mirrors the counter key pointfree derives in `verifySnapshot`: the resolved reference
  /// directory plus the unsanitized test name (swift-snapshot-testing 1.19.1,
  /// `AssertSnapshot.swift`), so distinct reference paths never share a count.
  private static func referenceCounterKey(for request: some AssertionRequesting) -> String {
    let fileUrl = URL(fileURLWithPath: "\(request.filePath)", isDirectory: false)
    let directoryUrl = request.snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
      ?? fileUrl
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileUrl.deletingPathExtension().lastPathComponent)

    return directoryUrl.appendingPathComponent(request.testName).absoluteString
  }
}

struct SnapshotError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
