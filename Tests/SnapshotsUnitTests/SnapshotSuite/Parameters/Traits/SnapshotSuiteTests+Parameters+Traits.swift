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
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
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
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.sizes(devices: .iPhoneX)).wrapped)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
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
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
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
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.sizes(devices: .iPhoneX)).wrapped, SnapshotTestingMacros.__SuiteTraitBox(.theme(.light)).wrapped)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
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
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
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
          @Suite(.pointfreeSnapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
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
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<(Int)>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<(Int)>(
                displayName: "makeView",
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
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.record).wrapped)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                SnapshotConfiguration(name: "1", value: 1),
                SnapshotConfiguration(name: "2", value: 2),
              ]))
            func makeView_snapshotTest(configuration: SnapshotConfiguration<(Int)>) async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: configuration)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }
  }
}
#endif
