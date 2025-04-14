#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct AsyncThrows {

    @Test
    func testFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() async throws -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() async throws -> some View {
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
                      try await SnapshotTests().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """
      }
    }

    @Test
    func testInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() async throws { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init() async throws { }

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
                      try await SnapshotTests().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 7,
                  column: 5
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
