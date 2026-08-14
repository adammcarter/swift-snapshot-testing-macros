import Testing

@testable import SnapshotTestingMacros

struct ResolvedSnapshotRuntimeStateTests {
  @Test
  func defaultsMatchTheApprovedSpec() throws {
    let runtime = ResolvedSnapshotRuntimeState.current
    let defaultSize = try #require(runtime.sizes.first)

    #expect(runtime.theme == .all)
    #expect(runtime.strategy == .image)
    // record/diffTool default to nil ("no trait set") so ambient pointfree configuration —
    // a consumer's `withSnapshotTesting`, the `.snapshots` trait, `SNAPSHOT_TESTING_RECORD` —
    // is inherited instead of clobbered.
    #expect(runtime.record == nil)
    #expect(runtime.diffTool == nil)
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
