import SwiftUI

public func __expectSnapshot<V: View>(
  _ value: sending V,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  ExpectSnapshotAdapter.run(
    value,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}
