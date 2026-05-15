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

  @Test
  func expandsNamedDirectValueAssertion() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(Text("test"), named: "custom")
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
            named: "custom",
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

  @Test
  func recoversWhenDirectValueIsMissing() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(named: "custom")
        }
      }
      """
    } diagnostics: {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(named: "custom")
          ┬───────────────────────────────
          ╰─ ⚠️ #expectSnapshot requires an unlabeled value argument.
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
          ()
        }
      }
      """
    }
  }
}
#endif
