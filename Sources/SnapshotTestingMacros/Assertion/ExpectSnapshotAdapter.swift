import SwiftUI
import Testing

private final class SnapshotValueBox<V>: @unchecked Sendable {
  let value: V

  init(_ value: V) {
    self.value = value
  }
}

enum ExpectSnapshotAdapter {
  static func run<V: View>(
    _ value: sending V,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let runtime = ResolvedSnapshotRuntimeState.current
      let displayName = context.resolvedAssertionName(named: named)
      let valueBox = SnapshotValueBox(value)

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: displayName,
            configuration: .none,
            makeValue: { (_: Void) async throws in valueBox.value },
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )

          try await runtime.withAppliedValues {
            try await assertSnapshot(with: generator)
          }
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }
}
