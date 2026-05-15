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
  func expandsConfigurationAssertionWithTrailingClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          let configuration = SnapshotConfiguration(name: nil, value: "test")
          #expectSnapshot(configuration) { value in
            Text(value)
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
          let configuration = SnapshotConfiguration(name: nil, value: "test")
          SnapshotTestingMacros.__expectSnapshot(
            configuration,
            named: nil,
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: { value in
                Text(value)
              }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsArgumentAssertionWithTrailingClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          #expectSnapshot(argument: state) { state in
            Text("\\(state.rawValue)")
          }
        }
      }
      """
    } expansion: {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          SnapshotTestingMacros.__expectSnapshot(
            argument: state,
            named: nil,
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: { state in
                Text("\\(state.rawValue)")
              }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsArgumentAssertionWithInParenthesesClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          #expectSnapshot(argument: state, { state in
            Text("\\(state.rawValue)")
          })
        }
      }
      """
    } expansion: {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          SnapshotTestingMacros.__expectSnapshot(
            argument: state,
            named: nil,
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: { state in
                Text("\\(state.rawValue)")
              }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsArgumentAssertionWithExplicitName() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          #expectSnapshot(argument: state, named: "custom") { state in
            Text("\\(state.rawValue)")
          }
        }
      }
      """
    } expansion: {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      enum CountState: Int, Sendable {
        case zero
      }

      struct MySnapshots {
        @Test
        func myView() {
          let state = CountState.zero
          SnapshotTestingMacros.__expectSnapshot(
            argument: state,
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: { state in
                Text("\\(state.rawValue)")
              }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsConfigurationAssertionWithInParenthesesClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          let configuration = SnapshotConfiguration(name: nil, value: "test")
          #expectSnapshot(configuration, { value in
            Text(value)
          })
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
          let configuration = SnapshotConfiguration(name: nil, value: "test")
          SnapshotTestingMacros.__expectSnapshot(
            configuration,
            named: nil,
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: { value in
                Text(value)
              }
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
          ╰─ 🛑 #expectSnapshot requires an unlabeled value argument or closure.
        }
      }
      """
    }
  }
}
#endif
