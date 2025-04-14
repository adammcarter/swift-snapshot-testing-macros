#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct BackgroundColor {

    @Test
    func testDefault() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
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
                  MySnapshots().makeView()
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

    @Test
    func testSettingColor() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .backgroundColor(.red)
        )
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
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
                traits: [.backgroundColor(.red), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  MySnapshots().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
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
