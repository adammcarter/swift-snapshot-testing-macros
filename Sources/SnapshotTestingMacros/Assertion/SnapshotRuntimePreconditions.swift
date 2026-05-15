import Testing

enum SnapshotRuntimePreconditions {
  static let activeTestTaskMessage =
    "#expectSnapshot(...) may only be used from the active Swift Testing test task. Detached tasks are unsupported."

  @discardableResult
  static func requireActiveTestContext(_ currentTest: Test?) -> Test {
    guard let currentTest else {
      preconditionFailure(activeTestTaskMessage)
    }

    return currentTest
  }
}
