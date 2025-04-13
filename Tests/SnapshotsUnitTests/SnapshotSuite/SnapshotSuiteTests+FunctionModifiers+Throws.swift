#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct Throws {

    @Test
    func testThrowingFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() throws -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() throws -> some View {
                Text("my view")
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
                            try SnapshotTests().makeMyView()
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
    func testNonThrowingFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            static func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests.makeMyView()
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
    func testThrowingInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() throws { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init() throws { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            try SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: 7,
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
    func testNonThrowingInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init() { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                        line: 7,
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
