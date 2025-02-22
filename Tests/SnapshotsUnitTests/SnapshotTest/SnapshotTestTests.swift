#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

@Suite(
  .macros(
    [
      "SnapshotSuite": SnapshotSuiteMacro.self,
      "SnapshotTest": SnapshotTestMacro.self,
    ],
    record: .missing
  )
)
struct SnapshotTestTests {

  @Suite
  struct Name {

    @Test
    func testPopulatedString() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
            @SnapshotTest("Some name")
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "Some name",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testEmptyString() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
            @SnapshotTest("")
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testNoName() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInheritName() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Suite name")
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "Suite name",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testBothNames() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Suite name")
        struct MySuite {
            @SnapshotTest("Test name")
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

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "Test name",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
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

extension SnapshotTestTests {

  @Suite
  struct Behaviour {

    @Test
    func testInheritingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ],
                behaviour: .inheritingConfigurations
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "2", value: 2),
                        ]))
                func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "aTest",
                        traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().aTest(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 10,
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
    func testReplacingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ],
                behaviour: .replacingConfigurations
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "2", value: 2),
                        ]))
                func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "aTest",
                        traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().aTest(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 10,
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
    func testDefaultValueIsReplacingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ]
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                            SnapshotConfiguration(name: "2", value: 2),
                        ]))
                func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "aTest",
                        traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: configuration,
                        makeValue: {
                            SnapshotTests().aTest(value: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 10,
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

extension SnapshotTestTests {

  @Suite
  struct MacroAttachments {

    @Test
    func testMissingSnapshotSuiteMacro() {
      assertMacro {
        """
        @MainActor
        @Suite
        enum MyTests {
            @SnapshotTest
            func aTest() -> some View {
                Text("test")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        enum MyTests {
            func aTest() -> some View {
                Text("test")
            }
        }
        """
      }
    }

    @Test
    func testInsideSuiteSingle() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func aTest() -> some View {
                Text("test")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest() -> some View {
                Text("test")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotATest() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "aTest",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().aTest()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInsideSuiteMixed() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            func aSuiteTest() -> some View {
                Text("suite")
            }

            @SnapshotTest
            func aTest() -> some View {
                Text("test")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            func aSuiteTest() -> some View {
                Text("suite")
            }
            func aTest() -> some View {
                Text("test")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotATest() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "aTest",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().aTest()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 9,
                        column: 5
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
#else
import Testing

#warning("TODO: these tests and others in this module only seem to build for mac, needs looking in to...")

@Suite(.disabled("Tests do not run on iOS - fix me")) enum Skip {}

#endif
