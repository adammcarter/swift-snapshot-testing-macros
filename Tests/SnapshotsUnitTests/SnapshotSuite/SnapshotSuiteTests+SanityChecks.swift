#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotSuiteTests {

  @Suite
  struct SanityChecks {}
}

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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }
  }
}
#endif
