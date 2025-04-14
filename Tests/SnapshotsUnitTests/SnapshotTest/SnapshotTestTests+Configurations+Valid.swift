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
            func makeAnotherView(input: String) -> some View {
                Text("\(#function) \(input)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeMyView(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeAnotherView(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeAnotherView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeAnotherView(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 14,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            func makeAnotherView(string: String, int: Int) -> some View {
                Text("\(#function) \(string) \(int)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: ("1", 1)),
                          SnapshotConfiguration(name: "Config2", value: ("2", 2)),
                      ]))
              func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String, Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeMyView(string: $0, int: $1)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: ("1", 1)),
                          SnapshotConfiguration(name: "Config2", value: ("2", 2)),
                      ]))
              func assertSnapshotMakeAnotherView(configuration: SnapshotConfiguration<(String, Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeAnotherView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeAnotherView(string: $0, int: $1)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 15,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().makeMyView(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }

              #if canImport(AppKit)
              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeViewController(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeViewController",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().makeViewController(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 15,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }

              #elseif canImport(UIKit)
              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeViewController(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeViewController",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().makeViewController(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 25,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }

              #else
              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "Config1", value: "1"),
                      ]))
              func assertSnapshotMakeViewController(configuration: SnapshotConfiguration<(String)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeViewController",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().makeViewController(input: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 35,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(getArgs()))
              func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeMyView(value: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 12,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(getArgs))
              func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      Tests().makeMyView(value: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 12,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """#
      }
    }
  }
}
#endif
