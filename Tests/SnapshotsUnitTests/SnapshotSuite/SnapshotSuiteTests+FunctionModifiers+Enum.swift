#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct Enum {
    @Test
    func testStaticFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        enum MyEnum {
            @SnapshotTest
            static func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        enum MyEnum {
            @SnapshotTest
            static func makeView() -> some View {
                Text("")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func assertSnapshotMakeView() async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: .none,
                  makeValue: {
                      MyEnum.makeView()
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
