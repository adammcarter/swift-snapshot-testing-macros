#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {

  @Suite
  struct Scope {

    @Test
    func testStatic() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          static func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          static func makeMyView() -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests.makeMyView()
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
            func assertSnapshotMakeMyView() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testNonStatic() {
      assertMacro {
        """
        @MainActor
        @Suite
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
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView()
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
            func assertSnapshotMakeMyView() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
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
