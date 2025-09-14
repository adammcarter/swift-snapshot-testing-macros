#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Tags {

    @Test
    func testAddingTags() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.tags(.someTag))
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.tags(.someTag), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
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
            @Test(.tags(.someTag))
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
    func testAddingReservedSnapshotsTag() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.tags(.snapshots))
        struct Tags {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } diagnostics: {
        """

        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.tags(.snapshots), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
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
            @Test(.tags(.snapshots))
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
    func testTagsDefault() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
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
  }
}
#endif
