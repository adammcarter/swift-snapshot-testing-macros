#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

  @Suite
  struct Attributes {

    @Test
    func onlySnapshotTest() {
      assertMacro {
        """
        @Suite
        @SnapshotSuite
        struct MySnapshots {
          @SnapshotTest
          func myView() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @Suite
        struct MySnapshots {
          func myView() -> some View {
            Text("test")
          }

          enum __generator_container_myView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "myView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().myView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 4,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func myView_snapshotTest() async throws {
              let generator = __generator_container_myView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func includesAvailable() {
      assertMacro {
        """
        @SnapshotSuite
        @Suite
        struct MySnapshots {
          @SnapshotTest
          @available(iOS 26.0, *)
          func myView() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @Suite
        struct MySnapshots {
          @available(iOS 26.0, *)
          func myView() -> some View {
            Text("test")
          }

          enum __generator_container_myView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "myView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().myView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 4,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            @available(iOS 26.0, *)
            func myView_snapshotTest() async throws {
              let generator = __generator_container_myView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func explicitlyIncludesMainActor() {
      assertMacro {
        """
        @SnapshotSuite
        @Suite
        struct MySnapshots {
          @MainActor
          @SnapshotTest
          func myView() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @Suite
        struct MySnapshots {
          @MainActor
          func myView() -> some View {
            Text("test")
          }

          enum __generator_container_myView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "myView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().myView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 4,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySnapshots_GeneratedSnapshotSuite {

            @Test()
            @MainActor
            func myView_snapshotTest() async throws {
              let generator = __generator_container_myView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func explicitlyIncludesViewBuilder() {
      assertMacro {
        """
        @SnapshotSuite
        @Suite
        struct MySnapshots {
          @SnapshotTest
          @ViewBuilder
          func myView() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @Suite
        struct MySnapshots {
          @ViewBuilder
          func myView() -> some View {
            Text("test")
          }

          enum __generator_container_myView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "myView",
                configuration: configuration,
                makeValue: {
                  MySnapshots().myView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 4,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySnapshots_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func myView_snapshotTest() async throws {
              let generator = __generator_container_myView.makeGenerator(configuration: .none)

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
