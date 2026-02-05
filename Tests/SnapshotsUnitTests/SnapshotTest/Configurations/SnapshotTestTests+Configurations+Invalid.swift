#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests.Configurations {

  @Suite
  struct Invalid {

    @Test
    func testNonStaticWithGoodReturnTypes() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
              SnapshotConfiguration(name: "Config2", value: "2"),
            ]
          )
          func makeAnotherView(input: String) -> some View {
            Text("another view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeAnotherView(input: String) -> some View {
            Text("another view")
          }

          enum __generator_container_makeAnotherView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<(String)>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<(String)>(
                displayName: "makeAnotherView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeAnotherView(input: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                  SnapshotConfiguration(name: "Config2", value: "2"),
                ]))
            func makeAnotherView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              let generator = __generator_container_makeAnotherView.makeGenerator(configuration: configuration)

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
