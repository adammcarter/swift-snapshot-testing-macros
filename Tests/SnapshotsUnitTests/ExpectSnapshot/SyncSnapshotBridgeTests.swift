import Testing

@testable import SnapshotTestingMacros

struct SyncSnapshotBridgeTests {
  @Test
  func runsMainActorOperationFromSyncCallSite() {
    let state = State()

    SyncSnapshotBridge.run(
      {
        state.didRun = true
      },
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )

    #expect(state.didRun)
  }
}

private final class State: @unchecked Sendable {
  var didRun = false
}
