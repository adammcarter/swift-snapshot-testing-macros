#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters {

  @Suite
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
            @SnapshotTest
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
                        traits: [.sizes(devices: .iPhoneX), .theme(.all), .strategy(.image), .record(false)],
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
            @SnapshotTest
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
                        traits: [.sizes(devices: .iPhoneX), .theme(.light), .strategy(.image), .record(false)],
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
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySuite().makeView()
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
            @SnapshotTest(configurations: [
                SnapshotConfiguration(name: "1", value: 1),
                SnapshotConfiguration(name: "2", value: 2),
            ])
            func makeView(value: Int) -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                        SnapshotConfiguration(name: "1", value: 1),
                        SnapshotConfiguration(name: "2", value: 2),
                    ]))
                func assertSnapshotMakeView(configuration: SnapshotConfiguration<(Int)>) async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.record(true), .theme(.all), .strategy(.image), .sizes(.minimum)],
                        configuration: configuration,
                        makeValue: {
                            MySuite().makeView(value: $0)
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
#endif
