import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

@MainActor
struct FailureReportingTests {
  @Test
  func issueMessageIncludesArtifactNameConfigurationDiffHintAndSourceLocation() {
    let request = MockRequest(testName: "logged-out_profileCard_dark")
    var capturedMessage: String?

    let asserter = IssueRecordingAsserter(
      base: MockAsserter(
        errorToThrow: SnapshotError(
          message: """
            snapshot mismatch: logged-out_profileCard_dark

            ksdiff "/tmp/reference.png" "/tmp/failure.png"
            """
        )
      ),
      recordIssue: { message, _, _, filePath, line, column in
        capturedMessage = "\(message ?? "") @ \(filePath):\(line):\(column)"
      }
    )

    asserter.assertSnapshot(request)

    #expect(capturedMessage?.contains("logged-out_profileCard_dark") == true)
    #expect(capturedMessage?.contains("logged-out") == true)
    #expect(capturedMessage?.contains("ksdiff") == true)
    #expect(capturedMessage?.contains("/path/to/file.swift:10:20") == true)
  }
}

private struct MockAsserter: SnapshotAsserting {
  let errorToThrow: Error?

  func assertSnapshot(_: any AssertionRequesting) throws {
    if let errorToThrow {
      throw errorToThrow
    }
  }
}

private struct MockRequest: AssertionRequesting {
  typealias Format = String

  let testName: String

  var view: SnapshotViewController { fatalError("Unused in this test") }
  var snapshotting: Snapshotting<SnapshotViewController, Format> { fatalError("Unused in this test") }
  var snapshotDirectory: String? { nil }
  var fileID: StaticString { "file.swift" }
  var filePath: StaticString { "/path/to/file.swift" }
  var line: UInt { 10 }
  var column: UInt { 20 }
}
