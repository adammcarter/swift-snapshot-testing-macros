#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.SanityChecks {

  @Suite
  struct Attributes {

    // A nested suite's attributes are indented. The fix-it must place `@Suite` on its own line
    // at that same indentation and push the displaced attribute down with it, rather than fusing
    // them into `  @Suite@MainActor`.
    @Test
    func nestedTestSuiteKeepsIndentation() {
      assertMacro {
        """
        enum Outer {
          @MainActor
          @SnapshotSuite
          struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
              Text("my view")
            }
          }
        }
        """
      } diagnostics: {
        """
        enum Outer {
          @MainActor
          @SnapshotSuite
          ┬─────────────
          ╰─ ⚠️ Add @Suite attribute to the test suite to easily run tests from Xcode.
             ✏️ Add @Suite attribute to SnapshotTests
          struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
              Text("my view")
            }
          }
        }
        """
      } fixes: {
        """
        enum Outer {
          @Suite
          @MainActor
          @SnapshotSuite
          struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
              Text("my view")
            }
          }
        }
        """
      } expansion: {
        """
        enum Outer {
          @Suite
          @MainActor
          struct SnapshotTests {
            func makeMyView() -> some View {
              Text("my view")
            }

            @MainActor
            @Suite(.pointfreeSnapshots)
            struct SnapshotTests_GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func makeMyView_snapshotTest() async throws {
                let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

                try await SnapshotTestingMacros.assertSnapshot(with: generator)
              }
            }
          }
        }
        """
      }
    }

    @Test
    func testSuite() {
      assertMacro {
        """
        @MainActor
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Add @Suite attribute to the test suite to easily run tests from Xcode.
           ✏️ Add @Suite attribute to SnapshotTests
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } fixes: {
        """
        @Suite
        @MainActor
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @Suite
        @MainActor
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }
  }
}
#endif
