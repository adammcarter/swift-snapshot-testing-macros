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
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
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
            @Test()
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
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.backgroundColor(.red), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots)
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test()
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
