#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Padding {

    @Test
    func testEdgesAndLength() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding(.all, 20.0))
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding(.all, 20.0)).wrapped)
          struct Tags_GeneratedSnapshotSuite {

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
    func testEdges() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding(.all))
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding(.all)).wrapped)
          struct Tags_GeneratedSnapshotSuite {

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
    func testLength() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding(20.0))
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding(20.0)).wrapped)
          struct Tags_GeneratedSnapshotSuite {

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
    func testEmpty() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding())
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding()).wrapped)
          struct Tags_GeneratedSnapshotSuite {

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
    func testProperty() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding)
        struct Tags {
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
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding).wrapped)
          struct Tags_GeneratedSnapshotSuite {

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
    func testInheritingPadding() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding)
        struct Tags {
          @SnapshotTest(.padding(20))
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct Tags {
          func makeView() -> some View {
            Text("input")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  Tags().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.padding).wrapped)
          struct Tags_GeneratedSnapshotSuite {

            @MainActor
            @Test(SnapshotTestingMacros.__TestTraitBox(.padding(20)).wrapped)
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

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
