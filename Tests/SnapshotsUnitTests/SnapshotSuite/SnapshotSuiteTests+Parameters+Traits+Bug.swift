#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Bug {

    @Test
    func testURL() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .bug("https://bugs.swift.org/browse/some-bug")
        )
        struct URL {
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
        struct URL {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.bug("https://bugs.swift.org/browse/some-bug"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  URL().makeView()
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

    @Test
    func testTitle() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .bug("https://bugs.swift.org/browse/some-bug", "A title")
        )
        struct Title {
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
        struct Title {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.bug("https://bugs.swift.org/browse/some-bug", "A title"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  Title().makeView()
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

    @Test
    func testID() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .bug(id: "some id")
        )
        struct ID {
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
        struct ID {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.bug(id: "some id"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  ID().makeView()
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
