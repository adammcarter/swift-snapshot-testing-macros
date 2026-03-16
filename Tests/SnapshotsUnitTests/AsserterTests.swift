import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

@MainActor
struct AsserterTests {

  @Test
  func testSnapshotErrorIsReportedAsMessageNotError() async throws {
    var capturedMessage: String?
    var capturedError: Error?

    let asserter = IssueRecordingAsserter(
      base: MockAsserter(errorToThrow: SnapshotError(message: "Expected failure message")),
      recordIssue: { message, error, _, _, _, _ in
        capturedMessage = message
        capturedError = error
      }
    )

    asserter.assertSnapshot(MockRequest())

    #expect(capturedMessage == "Expected failure message")
    #expect(capturedError == nil)
  }

  @Test
  func testUnexpectedErrorIsReportedAsError() async throws {
    struct SomeError: Error, Equatable {}

    var capturedMessage: String?
    var capturedError: Error?

    let asserter = IssueRecordingAsserter(
      base: MockAsserter(errorToThrow: SomeError()),
      recordIssue: { message, error, _, _, _, _ in
        capturedMessage = message
        capturedError = error
      }
    )

    asserter.assertSnapshot(MockRequest())

    #expect(capturedMessage == nil)
    #expect(capturedError is SomeError)
  }
}

// MARK: - Mocks

private struct MockAsserter: SnapshotAsserting {
  let errorToThrow: Error?

  func assertSnapshot(_: any AssertionRequesting) throws {
    if let error = errorToThrow {
      throw error
    }
  }
}

private struct MockRequest: AssertionRequesting {
  typealias Format = String

  var view: SnapshotViewController { fatalError("Should not be accessed") }
  var snapshotting: Snapshotting<SnapshotViewController, Format> { fatalError("Should not be accessed") }
  var snapshotDirectory: String? { nil }
  var fileID: StaticString { "file.swift" }
  var filePath: StaticString { "/path/to/file.swift" }
  var testName: String { "testName" }
  var line: UInt { 10 }
  var column: UInt { 20 }
}
