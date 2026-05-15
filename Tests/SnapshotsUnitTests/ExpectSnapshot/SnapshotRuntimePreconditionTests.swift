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
}
