import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

@MainActor
struct AsserterTests {

  @Test
  func testSnapshotErrorIsReportedAsMessageNotError() async throws {
    var captured = [SnapshotFailure]()

    let asserter = FailureCollectingAsserter(
      base: MockAsserter(errorToThrow: SnapshotError(message: "Expected failure message"))
    ) { failure in
      captured.append(failure)
    }

    asserter.assertSnapshot(MockRequest())

    #expect(captured.count == 1)
    #expect(captured.first?.message == "Expected failure message")
    #expect(captured.first?.error == nil)
  }

  @Test
  func testUnexpectedErrorIsReportedAsError() async throws {
    struct SomeError: Error, Equatable {}

    var captured = [SnapshotFailure]()

    let asserter = FailureCollectingAsserter(
      base: MockAsserter(errorToThrow: SomeError())
    ) { failure in
      captured.append(failure)
    }

    asserter.assertSnapshot(MockRequest())

    #expect(captured.count == 1)
    #expect(captured.first?.message == nil)
    #expect(captured.first?.error is SomeError)
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
