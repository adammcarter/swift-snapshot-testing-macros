#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotSuiteTests {
  @Suite
  struct Diagnostics {

    @Test
    func testBadReturnTypes() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeAnotherView(input: String) -> String {
                "another view"
            }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
        struct SnapshotTests {
            @SnapshotTest
            func makeAnotherView(input: String) -> String {
                "another view"
            }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeAnotherView(input: String) -> String {
                "another view"
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeAnotherView(input: String) -> String {
                "another view"
            }
        }
        """
      }
    }

    @Test
    func testStaticWithBadReturnTypes() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeAnotherView(input: String) -> String {
                Text("another view")
            }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
        struct SnapshotTests {
            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeAnotherView(input: String) -> String {
                Text("another view")
            }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeAnotherView(input: String) -> String {
                Text("another view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest(
                configurations: [
                    SnapshotConfiguration(name: "Config1", value: "1"),
                    SnapshotConfiguration(name: "Config2", value: "2"),
                ]
            )
            func makeAnotherView(input: String) -> String {
                Text("another view")
            }
        }
        """
      }
    }

    @Test
    func testMissingSnapshotTestAnnotation() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
           ✏️ Add @SnapshotTest annotations to viable functions.
        struct SnapshotTests {
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
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
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      }
    }

    @Test
    func testMultipleTests() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
           ✏️ Add @SnapshotTest annotations to viable functions.
        struct SnapshotTests {
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
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
            static func makeMyView() -> some View {
                Text("my view")
            }
        }
        """
      }
    }

    @Test
    func testSuiteMissingValidTests() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests { }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
        struct SnapshotTests { }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct SnapshotTests { }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests { }
        """
      }
    }

    #if os(macOS)
    @Test
    func testUIKitWhenTargetingMacOs() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeHostingController() -> UIViewController {
                UIHostingController(rootView: Text("hosting controller"))
            }

            @SnapshotTest
            func makeViewController() -> UIViewController {
                UIViewController()
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeHostingController() -> UIViewController {
                UIHostingController(rootView: Text("hosting controller"))
            }

            @SnapshotTest
            func makeViewController() -> UIViewController {
                UIViewController()
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeHostingController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeHostingController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeHostingController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }

                @MainActor
                @Test()
                func assertSnapshotMakeViewController() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeViewController",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests().makeViewController()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }
    #endif

    @Test
    func testEnumInstanceFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        enum MyEnum {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        enum MyEnum {
            @SnapshotTest
            ╰─ ⚠️ Cannot create a test for instance functions on types that cannot be initialised.
               ✏️ Make function static
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        enum MyEnum {
            @SnapshotTeststatic
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        enum MyEnum {
            @SnapshotTeststatic
            func makeView() -> some View {
                Text("")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {


            }
        }
        """
      }
    }
  }
}
#endif
