#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {

  @Suite
  struct AsyncThrows {

    @Test
    func testFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() async throws -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() async throws -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  try await SnapshotTests().makeMyView()
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
            func makeMyView_snapshotTest() async throws {
              let generator = __generator_container_makeMyView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    /// A suite with an `async throws` initialiser and a plain function is diagnosed for both the
    /// missing `async` and the missing `throws`; each fix-it adds *both* specifiers so applying
    /// either one yields an `async throws` function, and the peer then emits `try await`.
    @Test
    func testAsyncThrowsInitWithPlainFunctionIsDiagnosed() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() async throws { }

          @SnapshotTest
          func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() async throws { }

          @SnapshotTest
          ├─ 🛑 Cannot create a test for non-async instance functions on a suite with an 'async' initialiser. Make the function 'async' so the generated code can await the initialiser.
          │  ✏️ Make function async
          ╰─ 🛑 Cannot create a test for non-throwing instance functions on a suite with a 'throws' initialiser. Make the function 'throws' so the generated code can 'try' the initialiser.
             ✏️ Make function throws
          func makeMyView() -> some View {
            Text("my view")
          }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() async throws { }

          @SnapshotTest
          func makeMyView() async throws -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init() async throws { }
          func makeMyView() async throws -> some View {
            Text("my view")
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
          }
        }
        """
      }
    }
  }
}
#endif
