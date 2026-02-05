#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.NoParameters {

  @Suite
  struct Valid {

    @Test
    func testSwiftUI() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }

          @SnapshotTest
          func makeAnotherView() -> some View {
            Text("another view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeAnotherView() -> some View {
            Text("another view")
          }

          enum __generator_container_makeAnotherView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeAnotherView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeAnotherView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 10,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }

            @MainActor
            @Test()
            func makeAnotherView_snapshotTest() async throws {
              let generator = __generator_container_makeAnotherView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testPoundIfConditions() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }

        #if canImport(UIKit)
          @SnapshotTest
          func makeHostingController(input: String) -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }

          @SnapshotTest
          func makeViewController(input: String) -> UIViewController {
            SampleViewController()
          }
        #endif
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

        #if canImport(UIKit)
          func makeHostingController(input: String) -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }
          func makeViewController(input: String) -> UIViewController {
            SampleViewController()
          }
        #endif

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }

            #if canImport(UIKit)
            @MainActor
            @Test()
            func makeHostingController_snapshotTest() async throws {
              let generator = __generator_container_makeHostingController.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              let generator = __generator_container_makeViewController.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
            #endif
          }
        }
        """
      }
    }

    @Test
    func testPoundIfElseIfConditions() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }

        #if canImport(UIKit)
          @SnapshotTest
          func makeViewController() -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }
        #else
          @SnapshotTest
          func makeViewController() -> some View {
            #warning("Unsupported Kit")
          }
        #endif
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

        #if canImport(UIKit)
          func makeViewController() -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }
        #else
          func makeViewController() -> some View {
            #warning("Unsupported Kit")
          }
        #endif

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }

            #if canImport(UIKit)
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              let generator = __generator_container_makeViewController.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
            #else
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              let generator = __generator_container_makeViewController.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
            #endif
          }
        }
        """
      }
    }
  }
}
#endif
