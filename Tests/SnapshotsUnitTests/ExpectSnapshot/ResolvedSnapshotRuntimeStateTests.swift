import Testing

@testable import SnapshotTestingMacros

struct ResolvedSnapshotRuntimeStateTests {
  @Test
  func defaultsMatchTheApprovedSpec() {
    let runtime = ResolvedSnapshotRuntimeState.current

    #expect(runtime.theme == .all)
    #expect(runtime.strategy == .image)
    #expect(runtime.record == .missing)
    #expect(
      runtime.diffTool(currentFilePath: "current", failedFilePath: "failed")
        == DiffToolSnapshotTrait.DiffTool.default(currentFilePath: "current", failedFilePath: "failed")
    )
    #expect(runtime.sizes.count == 1)
    #expect(runtime.decoratorConfiguration?.backgroundColor == nil)
    #expect(runtime.decoratorConfiguration?.padding == nil)
  }
}
