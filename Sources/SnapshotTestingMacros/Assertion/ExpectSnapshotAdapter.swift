import SwiftUI
import Testing

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

    let displayName = TaskLocalSnapshotExecutionContext.withCurrent(function: function) {
      $0.resolvedAssertionName(named: named)
    }

    SyncSnapshotBridge.run(
      {
        let generator = SnapshotViewGenerator(
          displayName: displayName,
          configuration: .none,
          makeValue: { (_: Void) async throws in value },
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )

        try await assertSnapshot(with: generator)
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }
}
