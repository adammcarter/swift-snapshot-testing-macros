#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct DiffTool {

    @Test
    func missing() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
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
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDefault() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .diffTool(.default)
        )
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.diffTool(.default)).wrapped)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func ksdiff() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
          .diffTool(.ksdiff)
        )
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.diffTool(.ksdiff)).wrapped)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func custom() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
          .diffTool(.init { "someTool \($0) \($1)" })
        )
        struct MySnapshots {
          @SnapshotTest
          func makeView() -> some View {
            Text("")
          }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct MySnapshots {
          func makeView() -> some View {
            Text("")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.diffTool(.init {
                "someTool \($0) \($1)"
              })).wrapped)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """#
      }
    }
  }
}
#endif
