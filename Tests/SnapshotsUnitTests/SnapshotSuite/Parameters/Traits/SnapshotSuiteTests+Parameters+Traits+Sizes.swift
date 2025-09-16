#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Sizes {

    @Test
    func testWidthAndHeight() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(width: .minimum, height: .minimum))
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
                traits: [.sizes(width: .minimum, height: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
          struct Tags_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
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
    func testWidth() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(width: .minimum))
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
                traits: [.sizes(width: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
          struct Tags_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
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
    func testHeight() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(height: .minimum))
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
                traits: [.sizes(height: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
          struct Tags_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
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
    func testLength() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(.minimum))
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
                traits: [.sizes(.minimum), .theme(.all), .strategy(.image), .record(false)],
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
          struct Tags_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
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
