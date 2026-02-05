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
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
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
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.timeLimit(.minutes(1))).wrapped)
          struct TimeLimit_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

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
