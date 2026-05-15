import Foundation
import SnapshotTesting

/// Top level asserter - allows us to change the base and internals without updating the top level call site
struct Asserter {

  func assertSnapshots(from requests: [any AssertionRequesting]) async throws {
    if let test = Test.current {
      let trait: _SnapshotsTestTrait = .snapshots(
        record: RecordSnapshotTrait.current,
        diffTool: DiffToolSnapshotTrait.current
      )

      try await trait.provideScope(
        for: test,
        testCase: Test.Case.current,
        performing: Self.makeScopedAssertionOperation(requests: requests)
      )
    } else {
      await MainActor.run {
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
    }
  }

  private static func makeScopedAssertionOperation(
    requests: [any AssertionRequesting]
  ) -> @Sendable () async -> Void {
    { [requests] in
      await MainActor.run {
        performAssertions(
          using: IssueRecordingAsserter(base: PointfreeAsserter()),
          requests: requests
        )
      }
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
      throw SnapshotError(message: message)
    }
  }
}

struct SnapshotError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
