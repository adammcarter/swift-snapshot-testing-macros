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
          func makeView() -> some View {
              Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.timeLimit(.minutes(1)), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  TimeLimit().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots)
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.timeLimit(.minutes(1)))
            func assertSnapshotMakeView() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: .none)
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
