#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests.Configurations {

  @Suite
  struct Valid {

    @Test
    func testSingleArgument() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct Tests {
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeMyView(input: String) -> some View {
            Text("\(#function) \(input)")
          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeAnotherView(input: String) -> some View {
            Text("\(#function) \(input)")
          }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct Tests {
          func makeMyView(input: String) -> some View {
            Text("\(#function) \(input)")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeMyView(input: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeAnotherView(input: String) -> some View {
            Text("\(#function) \(input)")
          }

          enum __generator_container_makeAnotherView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeAnotherView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeAnotherView(input: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 14,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct Tests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeMyView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeAnotherView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeAnotherView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """#
      }
    }

    @Test
    func testMultipleArguments() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct Tests {
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: ("1", 1)),
              SnapshotConfiguration(name: "Config2", value: ("2", 2)),
            ]
          )
          func makeMyView(string: String, int: Int) -> some View {
            Text("\(#function) \(string) \(int)")
          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: ("1", 1)),
              SnapshotConfiguration(name: "Config2", value: ("2", 2)),
            ]
          )
          func makeAnotherView(string: String, int: Int) -> some View {
            Text("\(#function) \(string) \(int)")
          }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct Tests {
          func makeMyView(string: String, int: Int) -> some View {
            Text("\(#function) \(string) \(int)")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String, Int)>) -> SnapshotTestingMacros.SnapshotGenerator<(String, Int)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeMyView(string: $0, int: $1)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeAnotherView(string: String, int: Int) -> some View {
            Text("\(#function) \(string) \(int)")
          }

          enum __generator_container_makeAnotherView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String, Int)>) -> SnapshotTestingMacros.SnapshotGenerator<(String, Int)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeAnotherView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeAnotherView(string: $0, int: $1)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 15,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct Tests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: ("1", 1)),
                  SnapshotConfiguration(name: "Config2", value: ("2", 2)),
                ]))
            func makeMyView_snapshotTest(configuration: SnapshotConfiguration<(String, Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: ("1", 1)),
                  SnapshotConfiguration(name: "Config2", value: ("2", 2)),
                ]))
            func makeAnotherView_snapshotTest(configuration: SnapshotConfiguration<(String, Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeAnotherView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """#
      }
    }

    @Test
    func testPoundIfConditions() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeMyView(input: String) -> some View {
            Text("my view")
          }

        #if canImport(AppKit)
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeViewController(input: String) -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }

        #elseif canImport(UIKit)
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeViewController(input: String) -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }

        #else
          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
            ]
          )
          func makeViewController(input: String) -> some View {
            #warning("Unsupported Kit")
          }
        #endif
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView(input: String) -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView(input: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

        #if canImport(AppKit)
          func makeViewController(input: String) -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }

        #elseif canImport(UIKit)
          func makeViewController(input: String) -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }

        #else
          func makeViewController(input: String) -> some View {
            #warning("Unsupported Kit")
          }
        #endif

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeMyView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }

            #if canImport(AppKit)
            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeViewController_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: configuration)
              )
            }

            #elseif canImport(UIKit)
            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeViewController_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: configuration)
              )
            }

            #else
            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                ]))
            func makeViewController_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: configuration)
              )
            }
            #endif
          }
        }
        """
      }
    }

    @Test
    func testClosure() {
      assertMacro {
        #"""
        func getArgs() -> [SnapshotConfiguration<Int>] {
          [
            .init(name: "1", value: 1),
            .init(name: "2", value: 2),
          ]
        }

        @MainActor
        @Suite
        @SnapshotSuite
        struct Tests {
          @SnapshotTest(
            configurations: getArgs()
          )
          func makeMyView(value: Int) -> some View {
            Text("\(value)")
          }
        }
        """#
      } expansion: {
        #"""
        func getArgs() -> [SnapshotConfiguration<Int>] {
          [
            .init(name: "1", value: 1),
            .init(name: "2", value: 2),
          ]
        }

        @MainActor
        @Suite
        struct Tests {
          func makeMyView(value: Int) -> some View {
            Text("\(value)")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(Int)>) -> SnapshotTestingMacros.SnapshotGenerator<(Int)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 12,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct Tests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(getArgs()))
            func makeMyView_snapshotTest(configuration: SnapshotConfiguration<(Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """#
      }
    }

    @Test
    func testClosureWithFunctionReference() {
      assertMacro {
        #"""
        func getArgs() -> [SnapshotConfiguration<Int>] {
          [
            .init(name: "1", value: 1),
            .init(name: "2", value: 2),
          ]
        }

        @MainActor
        @Suite
        @SnapshotSuite
        struct Tests {
          @SnapshotTest(
            configurations: getArgs
          )
          func makeMyView(value: Int) -> some View {
            Text("\(value)")
          }
        }
        """#
      } expansion: {
        #"""
        func getArgs() -> [SnapshotConfiguration<Int>] {
          [
            .init(name: "1", value: 1),
            .init(name: "2", value: 2),
          ]
        }

        @MainActor
        @Suite
        struct Tests {
          func makeMyView(value: Int) -> some View {
            Text("\(value)")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(Int)>) -> SnapshotTestingMacros.SnapshotGenerator<(Int)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  Tests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 12,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct Tests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(getArgs))
            func makeMyView_snapshotTest(configuration: SnapshotConfiguration<(Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """#
      }
    }
  }
}
#endif
