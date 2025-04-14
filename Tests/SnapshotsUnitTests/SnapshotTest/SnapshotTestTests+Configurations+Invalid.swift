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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                          SnapshotConfiguration(name: "Config2", value: "2"),
                      ]))
              func assertSnapshotMakeAnotherView(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeAnotherView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().makeAnotherView(input: $0)
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
  }
}
#endif
