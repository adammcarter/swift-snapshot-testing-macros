#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

@Suite(
  .macros(
    [
      "expectSnapshot": ExpectSnapshotMacro.self,
    ],
    record: .missing
  )
)
struct ExpectSnapshotMacroTests {
  @Test
  func expandsPlainDirectValueAssertion() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(Text("test"))
        }
      }
      """
    } expansion: {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          SnapshotTestingMacros.__expectSnapshot(
            Text("test"),
            named: nil,
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column
          )
        }
      }
      """
    }
  }
}
#endif
