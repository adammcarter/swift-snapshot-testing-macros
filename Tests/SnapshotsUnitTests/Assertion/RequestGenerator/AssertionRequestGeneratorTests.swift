#if os(macOS)
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct AssertionRequestGeneratorTests {
  @Test
  func `builds snapshot directory without test folder`() {
    let directory = AssertionRequestGenerator.makeSnapshotDirectory(
      filePath: "/tmp/SnapshotTests.swift",
      testFolderName: nil
    )

    #expect(directory == "/tmp/__Snapshots__/SnapshotTests")
  }

  @Test
  func `builds snapshot directory with test folder`() {
    let directory = AssertionRequestGenerator.makeSnapshotDirectory(
      filePath: "/tmp/SnapshotTests.swift",
      testFolderName: "myView"
    )

    #expect(directory == "/tmp/__Snapshots__/SnapshotTests/myView")
  }
}
#endif
