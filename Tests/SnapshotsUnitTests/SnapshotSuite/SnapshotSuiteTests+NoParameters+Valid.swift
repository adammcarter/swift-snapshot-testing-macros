#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.NoParameters {
  @Suite
  struct Valid {

    @Test
    func testSwiftUI() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

            @SnapshotTest
            func makeAnotherView() -> some View {
                Text("another view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

            @SnapshotTest
            func makeAnotherView() -> some View {
                Text("another view")
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
                            SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }

                @MainActor
                @Test()
                func assertSnapshotMakeAnotherView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeAnotherView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeAnotherView()
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
        """
      }
    }

    @Test
    func testAppKit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeHostingController() -> NSViewController {
                NSHostingController(rootView: Text("hosting controller"))
            }

            @SnapshotTest
            func makeViewController() -> NSViewController {
                NSViewController()
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeHostingController() -> NSViewController {
                NSHostingController(rootView: Text("hosting controller"))
            }

            @SnapshotTest
            func makeViewController() -> NSViewController {
                NSViewController()
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeHostingController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeHostingController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeHostingController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 5,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }

                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController()
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
        """
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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

        #if canImport(AppKit)
                @SnapshotTest
                func makeHostingController(input: String) -> NSViewController {
                    NSHostingController(rootView: Text("hosting controller"))
                }

                @SnapshotTest
                func makeViewController(input: String) -> NSViewController {
                    SampleViewController()
                }
        #endif

        #if canImport(UIKit)
                @SnapshotTest
                func makeHostingController(input: String) -> UIViewController {
                    UIHostingController(rootView: Text("hosting controller"))
                }

                @SnapshotTest
                func makeViewController(input: String) -> UIViewController {
                    SampleViewController()
                }
        #endif
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

        #if canImport(AppKit)
                @SnapshotTest
                func makeHostingController(input: String) -> NSViewController {
                    NSHostingController(rootView: Text("hosting controller"))
                }

                @SnapshotTest
                func makeViewController(input: String) -> NSViewController {
                    SampleViewController()
                }
        #endif

        #if canImport(UIKit)
                @SnapshotTest
                func makeHostingController(input: String) -> UIViewController {
                    UIHostingController(rootView: Text("hosting controller"))
                }

                @SnapshotTest
                func makeViewController(input: String) -> UIViewController {
                    SampleViewController()
                }
        #endif

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
                            SnapshotTests().makeMyView()
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
                @Test()
                func assertSnapshotMakeHostingController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeHostingController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeHostingController(input: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 11,
                        column: 9
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController(input: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 16,
                        column: 9
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
                #endif

                #if canImport(UIKit)
                @MainActor
                @Test()
                func assertSnapshotMakeHostingController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeHostingController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeHostingController(input: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 23,
                        column: 9
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController(input: $0)
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 28,
                        column: 9
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
    func testPoundIfElseIfConditions() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

        #if canImport(AppKit)
            @SnapshotTest
            func makeViewController() -> NSViewController {
                NSHostingController(rootView: Text("hosting controller"))
            }
        #elseif canImport(UIKit)
            @SnapshotTest
            func makeViewController() -> UIViewController {
                UIHostingController(rootView: Text("hosting controller"))
            }
        #else
            @SnapshotTest
            func makeViewController() -> some View {
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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

        #if canImport(AppKit)
            @SnapshotTest
            func makeViewController() -> NSViewController {
                NSHostingController(rootView: Text("hosting controller"))
            }
        #elseif canImport(UIKit)
            @SnapshotTest
            func makeViewController() -> UIViewController {
                UIHostingController(rootView: Text("hosting controller"))
            }
        #else
            @SnapshotTest
            func makeViewController() -> some View {
                #warning("Unsupported Kit")
            }
        #endif

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
                            SnapshotTests().makeMyView()
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
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 11,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
                #elseif canImport(UIKit)
                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 16,
                        column: 5
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
                #else
                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 21,
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
  }
}
#endif
