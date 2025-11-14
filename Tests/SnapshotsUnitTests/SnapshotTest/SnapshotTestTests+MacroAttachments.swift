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

          enum __generator_container_aTest {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "aTest",
                configuration: configuration,
                makeValue: {
                  MyTests().aTest()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 4,
                column: 3
              )
            }
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

          enum __generator_container_aTest {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "aTest",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().aTest()
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
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func aTest_snapshotTest() async throws {
              let generator = __generator_container_aTest.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
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

          enum __generator_container_aTest {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "aTest",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().aTest()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 9,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func aTest_snapshotTest() async throws {
              let generator = __generator_container_aTest.makeGenerator(configuration: .none)

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
