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
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.enabled(if: false), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  EnabledIf().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct EnabledIf_GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled(if: false))
            func makeView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: .none)
              )
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
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.enabled(if: enableTests, "Some comment"), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  EnabledIfWithComment().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct EnabledIfWithComment_GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled(if: enableTests, "Some comment"))
            func makeView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: .none)
              )
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
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.enabled {
                    false
                  }, .theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  EnabledWithCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct EnabledWithCondition_GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled {
              false
            })
            func makeView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: .none)
              )
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
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.enabled("Some comment", {
                      enableTests
                    }), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  EnabledWithCommentAndCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct EnabledWithCommentAndCondition_GeneratedSnapshotSuite {

            @MainActor
            @Test(.enabled("Some comment", {
                enableTests
              }))
            func makeView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }
  }
}
#endif
