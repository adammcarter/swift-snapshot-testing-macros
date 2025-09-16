#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.SanityChecks {

  @Suite
  struct Attributes {

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
        @Suite@MainActor
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
        @Suite@MainActor
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          @MainActor
          @Suite(.snapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }
  }
}
#endif
