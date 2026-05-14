import SwiftUI

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
    let baseName = TaskLocalSnapshotExecutionContext.withCurrent(function: function) {
      $0.baseName
    }
    let displayName = displayName(named: named, baseName: baseName)

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
    named ?? baseName
  }
}
