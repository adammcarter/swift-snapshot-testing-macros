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
            named: nil,
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
            named: "custom",
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

  @Test
  func expandsThrowingDirectValueAsBuilderClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() throws {
          try #expectSnapshot(try makeView(), named: "custom")
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
        func myView() throws {
          try SnapshotTestingMacros.__expectSnapshot(
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              try makeView()
            }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsParenthesizedThrowingDirectValueAsBuilderClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() throws {
          try #expectSnapshot((try makeView()), named: "custom")
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
        func myView() throws {
          try SnapshotTestingMacros.__expectSnapshot(
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              (try makeView())
            }
          )
        }
      }
      """
    }
  }

  /// `await`, `try await`, and a `try` nested inside a larger expression all reach the same
  /// builder-closure expansion: the effects are the closure's, so the compiler picks the
  /// matching `makeValue:` overload without the macro classifying the expression at all.
  @Test
  func expandsAwaitingDirectValueAsBuilderClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() async {
          await #expectSnapshot(await makeView(), named: "custom")
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
        func myView() async {
          await SnapshotTestingMacros.__expectSnapshot(
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              await makeView()
            }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsThrowingAwaitingDirectValueAsBuilderClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() async throws {
          try await #expectSnapshot(try await makeView(), named: "custom")
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
        func myView() async throws {
          try await SnapshotTestingMacros.__expectSnapshot(
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              try await makeView()
            }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsNestedThrowingDirectValueAsBuilderClosure() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() throws {
          try #expectSnapshot(Wrapper(inner: try makeView()), named: "custom")
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
        func myView() throws {
          try SnapshotTestingMacros.__expectSnapshot(
            named: "custom",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              Wrapper(inner: try makeView())
            }
          )
        }
      }
      """
    }
  }

  /// `try?` and `try!` handle the error inside the expression, so the builder closure stays
  /// non-throwing and the call site needs no `try`.
  @Test
  func expandsOptionalAndForcedTryDirectValuesAsNonThrowingBuilderClosures() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(try? makeView(), named: "optional")
          #expectSnapshot(try! makeView(), named: "forced")
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
            named: "optional",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              try? makeView()
            }
          )
          SnapshotTestingMacros.__expectSnapshot(
            named: "forced",
            function: #function,
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column,
            makeValue: {
              try! makeView()
            }
          )
        }
      }
      """
    }
  }

  @Test
  func expandsThrowingArgumentAndConfigurationExpressionsWithoutDirectValueMarker() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      func loadArgument() throws -> String {
        "test"
      }

      func loadConfiguration() throws -> SnapshotConfiguration<String> {
        SnapshotConfiguration(name: nil, value: "test")
      }

      struct MySnapshots {
        @Test
        func myView() throws {
          try #expectSnapshot(argument: try loadArgument()) { value in
            Text(value)
          }

          try #expectSnapshot(try loadConfiguration()) { value in
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

      func loadArgument() throws -> String {
        "test"
      }

      func loadConfiguration() throws -> SnapshotConfiguration<String> {
        SnapshotConfiguration(name: nil, value: "test")
      }

      struct MySnapshots {
        @Test
        func myView() throws {
          try SnapshotTestingMacros.__expectSnapshot(
            argument: try loadArgument(),
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

          try SnapshotTestingMacros.__expectSnapshot(
            try loadConfiguration(),
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
  func expandsDirectValueWithTrailingLineComment() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(
            Text("test") // hero variant
          )
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
            named: nil,
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

  @Test
  func expandsNamedArgumentWithTrailingLineComment() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          #expectSnapshot(
            Text("test"),
            named: "custom" // reference note
          )
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
            named: "custom",
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

  @Test
  func expandsArgumentValueWithTrailingLineComment() {
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
          #expectSnapshot(
            argument: state // current case
          ) { state in
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
  func expandsFunctionReferenceMakeValueAfterConfiguration() {
    assertMacro {
      """
      import SnapshotTestingMacros
      import SwiftUI
      import Testing

      struct MySnapshots {
        @Test
        func myView() {
          let configuration = SnapshotConfiguration(name: nil, value: "test")
          #expectSnapshot(configuration, makeView)
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
            makeValue: makeView
          )
        }
      }
      """
    }
  }

  @Test
  func expandsFunctionReferenceMakeValueAfterArgument() {
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
          #expectSnapshot(argument: state, makeView)
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
            makeValue: makeView
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
