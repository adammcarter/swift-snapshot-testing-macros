import Foundation
import Testing

private final class SyncSnapshotBridgeResultBox: @unchecked Sendable {
  let lock = NSLock()
  var value: Result<Void, Error>?
}

enum SyncSnapshotBridge {
  static func run(
    _ operation: sending @escaping @MainActor () async throws -> Void,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    let resultBox = SyncSnapshotBridgeResultBox()
    let group = DispatchGroup()

    group.enter()
    Task {
      do {
        try await operation()
        resultBox.lock.withLock {
          resultBox.value = .success(())
        }
      } catch {
        resultBox.lock.withLock {
          resultBox.value = .failure(error)
        }
      }

      group.leave()
    }

    while group.wait(timeout: .now()) == .timedOut {
      RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
    }

    let finalResult = resultBox.lock.withLock { resultBox.value }

    if case .failure(let error)? = finalResult {
      Issue.record(
        error,
        sourceLocation: .init(
          fileID: fileID.description,
          filePath: filePath.description,
          line: Int(line),
          column: Int(column)
        )
      )
    }
  }
}
