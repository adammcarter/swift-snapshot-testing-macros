#if os(macOS)
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct AssertionRequestGeneratorTests {
  @Test
  func buildsSnapshotDirectoryWithoutTestFolder() {
    let directory = AssertionRequestGenerator.makeSnapshotDirectory(
      filePath: "/tmp/SnapshotTests.swift",
      testFolderName: nil
    )

    #expect(directory == "/tmp/__Snapshots__/SnapshotTests")
  }

  @Test
  func buildsSnapshotDirectoryWithTestFolder() {
    let directory = AssertionRequestGenerator.makeSnapshotDirectory(
      filePath: "/tmp/SnapshotTests.swift",
      testFolderName: "myView"
    )

    #expect(directory == "/tmp/__Snapshots__/SnapshotTests/myView")
  }
}
#endif
