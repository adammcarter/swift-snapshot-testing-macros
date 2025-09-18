#if os(macOS)
import MacroTesting
import SnapshotTestSupport
import Testing

extension SnapshotSuiteTests.Parameters {

  @Suite(.tags(.traits))
  struct Traits {

    @Test
    func testSingle() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(devices: .iPhoneX))
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.sizes(devices: .iPhoneX), .theme(.all), .strategy(.image), .record(false)],
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
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
    func testMany() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(devices: .iPhoneX), .theme(.light))
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.sizes(devices: .iPhoneX), .theme(.light), .strategy(.image), .record(false)],
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
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
    func testDefaultTraits() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
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
        struct MySuite {
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
                  MySuite().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct MySuite_GeneratedSnapshotSuite {

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
    func testInheritingTraitsWhenConfigurations() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.record)
        struct MySuite {
          @SnapshotTest(configurations: [
            SnapshotConfiguration(name: "1", value: 1),
            SnapshotConfiguration(name: "2", value: 2),
          ])
          func makeView(value: Int) -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeView(value: Int) -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(Int)>) -> SnapshotTestingMacros.SnapshotGenerator<(Int)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.record(true), .theme(.all), .strategy(.image), .sizes(.minimum)],
                configuration: configuration,
                makeValue: {
                  MySuite().makeView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                SnapshotConfiguration(name: "1", value: 1),
                SnapshotConfiguration(name: "2", value: 2),
              ]))
            func makeView_snapshotTest(configuration: SnapshotConfiguration<(Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: configuration)
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
