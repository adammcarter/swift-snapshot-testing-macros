#if os(macOS)
import MacroTesting
import Testing

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
#endif
