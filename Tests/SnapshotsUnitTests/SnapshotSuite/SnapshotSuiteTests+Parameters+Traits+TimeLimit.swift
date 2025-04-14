#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct TimeLimit {

    @Test
    func testTimeLimit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.timeLimit(.minutes(1)))
        struct TimeLimit {
          @SnapshotTest
          func makeView() -> some View {
              Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct TimeLimit {
          @SnapshotTest
          func makeView() -> some View {
              Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.timeLimit(.minutes(1)))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  TimeLimit().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
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
