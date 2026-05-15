import Foundation
import Testing

private struct SnapshotExecutionContextCacheKey: Hashable, Sendable {
  let testID: Test.ID?
  let caseIdentity: String
  let taskIdentity: UInt

  init?(currentTest: Test?, currentCase: Test.Case?) {
    guard let taskIdentity = Self.currentTaskIdentity() else {
      return nil
    }

    self.testID = currentTest?.id
    self.caseIdentity = currentCase.map(String.init(describing:)) ?? ""
    self.taskIdentity = taskIdentity
  }

  private static func currentTaskIdentity() -> UInt? {
    withUnsafeCurrentTask { task in
      task.map { task in
        withUnsafeBytes(of: task) { bytes in
          bytes.load(as: UInt.self)
        }
      }
    }
  }
}

private final class SnapshotExecutionContextCache: @unchecked Sendable {
  let lock = NSLock()
  var contexts: [SnapshotExecutionContextCacheKey: SnapshotExecutionContext] = [:]
}

enum TaskLocalSnapshotExecutionContext {
  private static let cache = SnapshotExecutionContextCache()

  @TaskLocal
  static var current: SnapshotExecutionContext?

  static func withCurrent<T>(
    function: StaticString,
    perform work: (SnapshotExecutionContext) throws -> T
  ) rethrows -> T {
    if let current {
      return try work(current)
    }

    let context: SnapshotExecutionContext
    if let key = SnapshotExecutionContextCacheKey(
      currentTest: Test.current,
      currentCase: Test.Case.current
    ) {
      context = cache.lock.withLock {
        if let existing = cache.contexts[key] {
          return existing
        }

        let created = SnapshotExecutionContext(function: function)
        cache.contexts[key] = created
        return created
      }
    }
    else {
      context = SnapshotExecutionContext(function: function)
    }

    return try $current.withValue(context) {
      try work(context)
    }
  }
}
