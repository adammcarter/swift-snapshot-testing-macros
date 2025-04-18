#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {

  @Suite(
    .disabled("Current limitation on recursive macro expansion.")
  )
  struct Subsuite {

    @Test
    func test() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }

          struct SubOne {
            @SnapshotTest
            func makeChildView() -> some View {
              Text("child view")
            }
          }
        }
        """
      }
    }

    @Test
    func testWithMix() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          struct SubOne {
            @SnapshotTest
            func makeMyView() -> some View {
              Text("my view")
            }
          }

          @MainActor
          @Suite
          @SnapshotSuite
          struct SubTwo {
            @SnapshotTest
            func makeAnotherView() -> some View {
              Text("another view")
            }
          }
        }
        """
      }
    }

    @Test
    func testWithArguments() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.record(true))
        struct SnapshotTests {
          struct SubOne {
            @SnapshotTest
            func makeMyView() -> some View {
              Text("my view")
            }
          }
        }
        """
      }
    }
  }
}
#endif
