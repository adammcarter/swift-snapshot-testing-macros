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
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.bug("https://bugs.swift.org/browse/some-bug"), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  URL().makeView()
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
            @Test(.bug("https://bugs.swift.org/browse/some-bug"))
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
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.bug("https://bugs.swift.org/browse/some-bug", "A title"), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  Title().makeView()
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
            @Test(.bug("https://bugs.swift.org/browse/some-bug", "A title"))
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
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.bug(id: "some id"), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  ID().makeView()
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
            @Test(.bug(id: "some id"))
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
