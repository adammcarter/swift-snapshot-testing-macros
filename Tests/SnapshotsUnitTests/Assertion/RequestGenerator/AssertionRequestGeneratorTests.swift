#if os(macOS)
import AppKit
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

  /// Slash-delimited display names must mean "subfolder" for configured (parameterized) tests
  /// exactly as they do for plain ones: `"Menu/Item"` nests `Menu/Item/` under the test file's
  /// snapshot folder and the final segment becomes the artifact name, instead of flattening
  /// the folder to `Menu-Item` and leaking the raw `/` into the test name.
  @Test
  func slashDisplayNameNestsTheSnapshotFolderForConfiguredTests() throws {
    let request = try makeSingleRequest(
      displayName: "Menu/Item",
      configuration: SnapshotConfiguration(name: "compact", value: 1)
    )

    #expect(request.snapshotDirectory == "/tmp/__Snapshots__/MySuiteTests/Menu/Item")
    #expect(request.testName == "compact_Item_min-size_light")
  }

  @Test
  func plainDisplayNameKeepsTheFlatConfiguredFolder() throws {
    let request = try makeSingleRequest(
      displayName: "Cards",
      configuration: SnapshotConfiguration(name: "compact", value: 1)
    )

    #expect(request.snapshotDirectory == "/tmp/__Snapshots__/MySuiteTests/Cards")
    #expect(request.testName == "compact_Cards_min-size_light")
  }

  private func makeSingleRequest(
    displayName: String,
    configuration: SnapshotConfiguration<Int>
  ) throws -> any AssertionRequesting {
    let viewGenerator = SnapshotViewGenerator<Int>(
      displayName: displayName,
      configuration: configuration,
      makeValue: { _ in
        let controller = SnapshotViewController()
        controller.view = SnapshotView(frame: .init(x: 0, y: 0, width: 200, height: 100))
        return controller
      },
      fileID: "fileID",
      filePath: "/tmp/MySuiteTests.swift",
      line: 1,
      column: 1
    )

    let size = SizesSnapshotTrait.Size(
      width: .fixed(200),
      height: .fixed(100),
      displayName: "size",
      debugDescription: "fixed 200x100",
      testNameDescription: "min-size"
    )

    let requests = try SizesSnapshotTrait.$current.withValue([size]) {
      try ThemeSnapshotTrait.$current.withValue(.light) {
        try StrategySnapshotTrait.$current.withValue(.recursiveDescription) {
          try AssertionRequestGenerator(viewGenerator: viewGenerator).generateRequestsSync()
        }
      }
    }

    #expect(requests.count == 1)
    return try #require(requests.first)
  }
}
#endif
