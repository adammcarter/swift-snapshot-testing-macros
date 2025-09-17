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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeAnotherView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
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
          @Suite(.snapshots(diffTool: .default))
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }

            @MainActor
            @Test()
            func makeAnotherView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeAnotherView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testAppKit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeHostingController() -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }

          @SnapshotTest
          func makeViewController() -> NSViewController {
            NSViewController()
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeHostingController() -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }

          enum __generator_container_makeHostingController {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeHostingController",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeHostingController()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeViewController() -> NSViewController {
            NSViewController()
          }

          enum __generator_container_makeViewController {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeViewController",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeViewController()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 10,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeHostingController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeHostingController.makeGenerator(configuration: .none)
              )
            }

            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
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

        #if canImport(AppKit)
          @SnapshotTest
          func makeHostingController(input: String) -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }

          @SnapshotTest
          func makeViewController(input: String) -> NSViewController {
            SampleViewController()
          }
        #endif

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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
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

        #if canImport(AppKit)
          func makeHostingController(input: String) -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }
          func makeViewController(input: String) -> NSViewController {
            SampleViewController()
          }
        #endif

        #if canImport(UIKit)
          func makeHostingController(input: String) -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }
          func makeViewController(input: String) -> UIViewController {
            SampleViewController()
          }
        #endif

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }

            #if canImport(AppKit)
            @MainActor
            @Test()
            func makeHostingController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeHostingController.makeGenerator(configuration: .none)
              )
            }
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
            }
            #endif

            #if canImport(UIKit)
            @MainActor
            @Test()
            func makeHostingController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeHostingController.makeGenerator(configuration: .none)
              )
            }
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
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

        #if canImport(AppKit)
          @SnapshotTest
          func makeViewController() -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }
        #elseif canImport(UIKit)
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false), .diffTool(.default)],
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

        #if canImport(AppKit)
          func makeViewController() -> NSViewController {
            NSHostingController(rootView: Text("hosting controller"))
          }
        #elseif canImport(UIKit)
          func makeViewController() -> UIViewController {
            UIHostingController(rootView: Text("hosting controller"))
          }
        #else
          func makeViewController() -> some View {
            #warning("Unsupported Kit")
          }
        #endif

          @MainActor
          @Suite(.snapshots(diffTool: .default))
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }

            #if canImport(AppKit)
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
            }
            #elseif canImport(UIKit)
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
            }
            #else
            @MainActor
            @Test()
            func makeViewController_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeViewController.makeGenerator(configuration: .none)
              )
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
