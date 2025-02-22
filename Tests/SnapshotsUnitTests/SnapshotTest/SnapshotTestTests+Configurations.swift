#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotTestTests {

  @Suite
  struct Configurations {}
}

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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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
                        line: #line,
                        column: #column
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

extension SnapshotTestTests.Configurations {

  @Suite
  struct Invalid {

    @Test
    func testNonStaticWithGoodReturnTypes() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeAnotherView(input: String) -> some View {
                Text("another view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            func makeAnotherView(input: String) -> some View {
                Text("another view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "Config1", value: "1"),
                            SnapshotConfiguration(name: "Config2", value: "2"),
                        ]))
                func assertSnapshotMakeAnotherView(configuration: SnapshotConfiguration<(String)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeAnotherView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().makeAnotherView(input: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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

extension SnapshotTestTests.Configurations {

  @Suite
  struct Init {

    @Test
    func testInitPassesConfigurationWhenInitWithConfiguration() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init(configuration: SnapshotConfiguration<String>) {

            }

            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeMyView(value: String) -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init(configuration: SnapshotConfiguration<String>) {

            }
            func makeMyView(value: String) -> some View {
                Text("my view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "Config1", value: "1"),
                            SnapshotConfiguration(name: "Config2", value: "2"),
                        ]))
                func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests(configuration: configuration).makeMyView(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInitPassesConfigurationWhenInitWithConfigurationButDifferentArgName() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init(gfds: SnapshotConfiguration<String>) {

            }

            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeMyView(value: String) -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init(gfds: SnapshotConfiguration<String>) {

            }
            func makeMyView(value: String) -> some View {
                Text("my view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "Config1", value: "1"),
                            SnapshotConfiguration(name: "Config2", value: "2"),
                        ]))
                func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests(gfds: configuration).makeMyView(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInitIgnoresConfigurationWhenEmptyInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() {

            }

            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeMyView(value: String) -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init() {

            }
            func makeMyView(value: String) -> some View {
                Text("my view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "Config1", value: "1"),
                            SnapshotConfiguration(name: "Config2", value: "2"),
                        ]))
                func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().makeMyView(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInitIgnoresConfigurationWhenInitWithWrongType() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init(configuration: String) {

            }

            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeMyView(value: String) -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init(configuration: String) {

            }
            func makeMyView(value: String) -> some View {
                Text("my view")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "Config1", value: "1"),
                            SnapshotConfiguration(name: "Config2", value: "2"),
                        ]))
                func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().makeMyView(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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
