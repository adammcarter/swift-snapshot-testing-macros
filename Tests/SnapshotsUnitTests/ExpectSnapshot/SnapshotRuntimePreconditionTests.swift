import Testing

@testable import SnapshotTestingMacros

struct SnapshotRuntimePreconditionTests {
  @Test
  func outsideActiveTestUsesClearFailureMessage() {
    #expect(
      SnapshotRuntimePreconditions.activeTestTaskMessage
        == "#expectSnapshot(...) may only be used from the active Swift Testing test task. Detached tasks are unsupported."
    )
  }

  @Test
  func missingTestContextRecordsIssueInsteadOfTrapping() {
    var recordedComments: [String] = []
    var recordedLocations: [SourceLocation] = []

    let test = SnapshotRuntimePreconditions.requireActiveTestContext(
      nil,
      fileID: "Module/File.swift",
      filePath: "/tmp/File.swift",
      line: 42,
      column: 7,
      recordIssue: { comment, sourceLocation in
        recordedComments.append(comment.description)
        recordedLocations.append(sourceLocation)
      }
    )

    #expect(test == nil)
    #expect(recordedComments == [SnapshotRuntimePreconditions.activeTestTaskMessage])
    #expect(recordedLocations.first?.fileID == "Module/File.swift")
    #expect(recordedLocations.first?.line == 42)
    #expect(recordedLocations.first?.column == 7)
  }

  @Test
  func activeTestContextPassesThroughWithoutRecording() throws {
    var recordedComments: [String] = []

    let currentTest = try #require(Test.current)
    let test = SnapshotRuntimePreconditions.requireActiveTestContext(
      currentTest,
      recordIssue: { comment, _ in recordedComments.append(comment.description) }
    )

    #expect(test?.id == currentTest.id)
    #expect(recordedComments.isEmpty)
  }

  @Test
  func missingMainActorResultRecordsFailureAtTheAssertionInsteadOfTrapping() {
    var recordedFailures: [SnapshotFailure] = []

    let value = SnapshotRuntimePreconditions.requireMainActorResult(
      String?.none,
      fallback: "fallback",
      message: "AppKit snapshot render returned no image.",
      fileID: "Module/File.swift",
      filePath: "/tmp/File.swift",
      line: 42,
      column: 7,
      recordFailure: { recordedFailures.append($0) }
    )

    #expect(value == "fallback")
    #expect(recordedFailures.count == 1)
    #expect(recordedFailures.first?.message == "AppKit snapshot render returned no image.")
    #expect(recordedFailures.first?.error == nil)
    #expect(recordedFailures.first?.fileID.description == "Module/File.swift")
    #expect(recordedFailures.first?.line == 42)
    #expect(recordedFailures.first?.column == 7)
  }

  @Test
  func presentMainActorResultPassesThroughWithoutRecording() {
    var recordedFailures: [SnapshotFailure] = []

    let value = SnapshotRuntimePreconditions.requireMainActorResult(
      "rendered",
      fallback: "fallback",
      message: "AppKit snapshot render returned no image.",
      fileID: "Module/File.swift",
      filePath: "/tmp/File.swift",
      line: 42,
      column: 7,
      recordFailure: { recordedFailures.append($0) }
    )

    #expect(value == "rendered")
    #expect(recordedFailures.isEmpty)
  }
}
