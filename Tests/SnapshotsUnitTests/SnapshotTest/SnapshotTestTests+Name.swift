#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

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
#endif
