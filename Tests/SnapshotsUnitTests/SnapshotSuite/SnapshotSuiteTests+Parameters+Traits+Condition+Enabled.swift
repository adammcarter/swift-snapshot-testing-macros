#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits.Condition {

  @Suite
  struct Enabled {

    @Test
    func testEnabledIf() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled(if: false))
        struct EnabledIf {
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
        struct EnabledIf {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled(if: false))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  EnabledIf().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testEnabledIfWithComment() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled(if: enableTests, "Some comment"))
        struct EnabledIfWithComment {
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
        struct EnabledIfWithComment {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled(if: enableTests, "Some comment"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  EnabledIfWithComment().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testEnabledWithCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled { false })
        struct EnabledWithCondition {
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
        struct EnabledWithCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled {
              false
            })
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  EnabledWithCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testEnabledWithCommentAndCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled("Some comment", { enableTests }))
        struct EnabledWithCommentAndCondition {
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
        struct EnabledWithCommentAndCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled("Some comment", {
                enableTests
              }))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  EnabledWithCommentAndCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
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
