import Foundation
import SnapshotTesting

/// Top level asserter - allows us to change the base and internals without updating the top level call site
@MainActor
struct Asserter {

  func assertSnapshots(from requests: [any AssertionRequesting]) {
    let asserter = IssueRecordingAsserter(base: PointfreeAsserter())

    for request in requests {
      asserter.assertSnapshot(request)
    }
  }
}

// MARK: - Asserters

@MainActor
private protocol SnapshotAsserting {

  func assertSnapshot(_ request: any AssertionRequesting) throws
}

// MARK: - IssueRecordingAsserter

#if canImport(Testing)
import Testing
#endif

/// Record issues on throw
private struct IssueRecordingAsserter: SnapshotAsserting {
  let base: any SnapshotAsserting

  func assertSnapshot(_ request: any AssertionRequesting) {
    do {
      try base.assertSnapshot(request)
    }
    catch {
      recordIssue(
        error: error,
        fileID: request.fileID,
        filePath: request.filePath,
        line: request.line,
        column: request.column
      )
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
    try SnapshotTesting.withSnapshotTesting(
      record: RecordSnapshotTrait.current,
      diffTool: DiffToolSnapshotTrait.current
    ) {
      try verifySnapshot(request: request)
    }
  }

  #warning("TODO: Allow timeout customisation via new trait")

  private func verifySnapshot(request: some AssertionRequesting) throws {
    let message = SnapshotTesting.verifySnapshot(
      of: request.view,
      as: request.snapshotting,
      named: nil,
      snapshotDirectory: request.snapshotDirectory,
      timeout: 5,
      fileID: request.fileID,
      file: request.filePath,
      testName: request.testName,
      line: request.line,
      column: request.column
    )

    if let message {
      throw message
    }
  }
}
