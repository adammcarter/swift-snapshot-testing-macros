import Testing

@testable import SnapshotTestingMacros

struct ResolvedSnapshotRuntimeStateTests {
  @Test
  func defaultsMatchTheApprovedSpec() {
    let runtime = ResolvedSnapshotRuntimeState.current
    let defaultSize = try! #require(runtime.sizes.first)

    #expect(runtime.theme == .all)
    #expect(runtime.strategy == .image)
    #expect(runtime.record == .missing)
    #expect(
      runtime.diffTool(currentFilePath: "current", failedFilePath: "failed")
        == DiffToolSnapshotTrait.DiffTool.default(currentFilePath: "current", failedFilePath: "failed")
    )
    #expect(runtime.sizes.count == 1)
    switch (defaultSize.width, defaultSize.height) {
      case (.minimum, .minimum):
        break
      default:
        Issue.record("Expected the default runtime size to be minimum width and minimum height.")
    }
    #expect(defaultSize.scale == nil)
    #expect(runtime.decoratorConfiguration?.backgroundColor == nil)
    #expect(runtime.decoratorConfiguration?.padding == nil)
  }
}
