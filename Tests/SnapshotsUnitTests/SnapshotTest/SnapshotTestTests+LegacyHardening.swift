#if os(macOS)
import MacroTesting
import SnapshotsMacros
import Testing

/// Regression coverage for the legacy-macro hardening batch: shapes that previously expanded
/// into silently-broken or silently-missing code now either expand correctly or are rejected
/// with a compile-time diagnostic.
extension SnapshotTestTests {

  @Suite
  struct LegacyHardening {

    // MARK: Finding 3 — parameterised test without configurations

    @Test
    func parameterisedWithoutConfigurationsIsRejected() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeView(input: String) -> some View {
            Text(input)
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          ┬────────────
          ╰─ 🛑 A parameterised '@SnapshotTest' function requires a 'configurations:' or 'configurationValues:' argument.
          func makeView(input: String) -> some View {
            Text(input)
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      }
    }

    // MARK: Finding 4 — @available is copied to the generated container

    @Test
    func availableAttributeIsCopiedToContainer() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          @available(iOS 17.0, *)
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          @available(iOS 17.0, *)
          func makeView() -> some View {
            Text("view")
          }

          @available(iOS 17.0, *)
          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeView()
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
            @available(iOS 17.0, *)
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    // MARK: Finding 6 — nil display names are not traits

    @Test
    func nilDisplayNameIsNotBoxedAsATrait() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(nil, .record(.all))
        struct SnapshotTests {
          @SnapshotTest(nil, .theme(.light))
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeView() -> some View {
            Text("view")
          }

          enum __generator_container_makeView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.record(.all)).wrapped)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test(SnapshotTestingMacros.__TestTraitBox(.theme(.light)).wrapped)
            func makeView_snapshotTest() async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    // MARK: Finding 6 — interpolated display names are rejected

    @Test
    func interpolatedDisplayNamesAreRejected() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite("Suite \(1)")
        struct SnapshotTests {
          @SnapshotTest("Test \(2)")
          func makeView() -> some View {
            Text("view")
          }
        }
        """#
      } diagnostics: {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite("Suite \(1)")
        ┬───────────────────────────
        ╰─ 🛑 A '@SnapshotSuite' display name must be a simple string literal; interpolation is not supported.
        struct SnapshotTests {
          @SnapshotTest("Test \(2)")
          ┬─────────────────────────
          ╰─ 🛑 A '@SnapshotTest' display name must be a simple string literal; interpolation is not supported.
          func makeView() -> some View {
            Text("view")
          }
        }
        """#
      }
    }

    // MARK: Finding 7 — unsupported return types are rejected

    @Test
    func unsupportedReturnTypeIsRejected() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeText() -> Text {
            Text("view")
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          ┬────────────
          ╰─ 🛑 '@SnapshotTest' does not support the return type 'Text'. Supported return types: NSView, NSViewController, UIView, UIViewController, some View.
          func makeText() -> Text {
            Text("view")
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      }
    }

    // MARK: Finding 8 — @SnapshotTest on a non-function is rejected

    @Test
    func nonFunctionDeclarationIsRejected() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          var makeView: some View {
            Text("view")
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          ┬────────────
          ╰─ 🛑 '@SnapshotTest' can only be applied to functions.
          var makeView: some View {
            Text("view")
          }

          @SnapshotTest
          func makeValidView() -> some View {
            Text("valid")
          }
        }
        """
      }
    }

    // MARK: Finding 9 — bare @SnapshotTest without a @SnapshotSuite emits nothing

    @Test
    func bareSnapshotTestWithoutSuiteWarnsAndEmitsNothing() {
      assertMacro {
        """
        struct PlainType {
          @SnapshotTest
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      } diagnostics: {
        """
        struct PlainType {
          @SnapshotTest
          ┬────────────
          ╰─ ⚠️ '@SnapshotTest' has no effect without an enclosing '@SnapshotSuite' type; no snapshot test will be generated.
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      } expansion: {
        """
        struct PlainType {
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      }
    }

    // MARK: Finding 10 — suites that cannot be initialised are rejected

    @Test
    func requiredParameterInitIsRejected() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let value: Int

          init(value: Int) {
            self.value = value
          }

          @SnapshotTest
          func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } diagnostics: {
        #"""
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
          let value: Int

          init(value: Int) {
            self.value = value
          }

          @SnapshotTest
          ╰─ 🛑 Cannot create a test for instance functions on types that cannot be initialised.
             ✏️ Make function static
          func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } fixes: {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let value: Int

          init(value: Int) {
            self.value = value
          }

          @SnapshotTest
          static func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
          let value: Int

          init(value: Int) {
            self.value = value
          }
          static func makeView() -> some View {
            Text("\(value)")
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

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

    @Test
    func storedPropertyWithoutDefaultIsRejected() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let value: Int

          @SnapshotTest
          func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } diagnostics: {
        #"""
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
          let value: Int

          @SnapshotTest
          ╰─ 🛑 Cannot create a test for instance functions on types that cannot be initialised.
             ✏️ Make function static
          func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } fixes: {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let value: Int

          @SnapshotTest
          static func makeView() -> some View {
            Text("\(value)")
          }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
          let value: Int
          static func makeView() -> some View {
            Text("\(value)")
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

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

    // MARK: Finding 10 — initialisers requiring a SnapshotConfiguration are rejected
    //
    // The peer macro cannot see the suite's initialisers (lexical contexts strip member
    // lists), so it can never pass a configuration to the initialiser. Both the unqualified
    // and the namespaced spelling previously generated a broken `SnapshotTests()` call —
    // the namespaced one silently, the unqualified one equally silently because the
    // configuration-forwarding path was unreachable. Both are now rejected loudly.

    @Test
    func unqualifiedConfigurationInitParameterIsRejected() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let configuration: SnapshotConfiguration<String>

          init(configuration: SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          func makeView(input: String) -> some View {
            Text(input)
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
          let configuration: SnapshotConfiguration<String>

          init(configuration: SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          ╰─ 🛑 Cannot create a test for instance functions on types that cannot be initialised.
             ✏️ Make function static
          func makeView(input: String) -> some View {
            Text(input)
          }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let configuration: SnapshotConfiguration<String>

          init(configuration: SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          static func makeView(input: String) -> some View {
            Text(input)
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          let configuration: SnapshotConfiguration<String>

          init(configuration: SnapshotConfiguration<String>) {
            self.configuration = configuration
          }
          static func makeView(input: String) -> some View {
            Text(input)
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(["a"]))
            func makeView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: configuration)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func namespacedConfigurationInitParameterIsRejected() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let configuration: SnapshotTestingMacros.SnapshotConfiguration<String>

          init(configuration: SnapshotTestingMacros.SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          func makeView(input: String) -> some View {
            Text(input)
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
          let configuration: SnapshotTestingMacros.SnapshotConfiguration<String>

          init(configuration: SnapshotTestingMacros.SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          ╰─ 🛑 Cannot create a test for instance functions on types that cannot be initialised.
             ✏️ Make function static
          func makeView(input: String) -> some View {
            Text(input)
          }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          let configuration: SnapshotTestingMacros.SnapshotConfiguration<String>

          init(configuration: SnapshotTestingMacros.SnapshotConfiguration<String>) {
            self.configuration = configuration
          }

          @SnapshotTest(configurationValues: ["a"])
          static func makeView(input: String) -> some View {
            Text(input)
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          let configuration: SnapshotTestingMacros.SnapshotConfiguration<String>

          init(configuration: SnapshotTestingMacros.SnapshotConfiguration<String>) {
            self.configuration = configuration
          }
          static func makeView(input: String) -> some View {
            Text(input)
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse(["a"]))
            func makeView_snapshotTest(configuration: SnapshotConfiguration<(String)>) async throws {
              let generator = __generator_container_makeView.makeGenerator(configuration: configuration)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    // MARK: Finding 10 — @SnapshotSuite on an extension is rejected

    @Test
    func extensionSuiteIsRejected() {
      assertMacro {
        """
        @SnapshotSuite
        extension SnapshotTests {
          @SnapshotTest
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      } diagnostics: {
        """
        @SnapshotSuite
        ┬─────────────
        ╰─ 🛑 '@SnapshotSuite' cannot be applied to extensions. Apply it to the type declaration instead.
        extension SnapshotTests {
          @SnapshotTest
          func makeView() -> some View {
            Text("view")
          }
        }
        """
      }
    }
  }
}
#endif
