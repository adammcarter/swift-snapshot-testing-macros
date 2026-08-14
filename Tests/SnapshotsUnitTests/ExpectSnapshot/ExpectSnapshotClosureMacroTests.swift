#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

@Suite(
  .macros(
    [
      "expectSnapshot": ExpectSnapshotMacro.self
    ],
    record: .missing
  )
)
struct ExpectSnapshotClosureMacroTests {
  @Test
  func expandsSyncClosureAssertion() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(named: "closure") {
            Text("test")
          }
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
            named: "closure",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
                Text("test")
              }
          )
        }
      }
      """
    }
  }
}
#endif
