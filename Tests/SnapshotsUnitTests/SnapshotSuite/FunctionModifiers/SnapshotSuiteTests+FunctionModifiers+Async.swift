#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {

  @Suite
  struct Async {

    @Test
    func testAsyncFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func makeMyView() async -> some View {
              Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func makeMyView() async -> some View {
              Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  await SnapshotTests().makeMyView()
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

    @Test
    func testNonAsyncFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
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

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  SnapshotTests.makeMyView()
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

    /// The peer macro cannot see the suite's initialiser (lexical contexts strip member
    /// lists), so it cannot emit `await` for a non-async function on an async-init suite. The
    /// suite macro — which can see the initialiser — must diagnose the shape instead of
    /// letting the generated container fail to compile with a cryptic error.
    @Test
    func testAsyncInitWithNonAsyncFunctionIsDiagnosed() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() async { }

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
          init() async { }

          @SnapshotTest
          ╰─ 🛑 Cannot create a test for non-async instance functions on a suite with an 'async' initialiser. Make the function 'async' so the generated code can await the initialiser.
             ✏️ Make function async
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
          init() async { }

          @SnapshotTest
          func makeMyView() async -> some View {
              Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init() async { }
          func makeMyView() async -> some View {
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

    /// An async function's `await` covers the async initialiser call too, so this shape is
    /// supported: the generated `makeValue` awaits `SnapshotTests().makeMyView()` as one
    /// expression.
    @Test
    func testAsyncInitWithAsyncFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() async { }

          @SnapshotTest
          func makeMyView() async -> some View {
              Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init() async { }
          func makeMyView() async -> some View {
              Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  await SnapshotTests().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 7,
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

    @Test
    func testNonAsyncInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() { }

          @SnapshotTest
          func makeMyView() -> some View {
              Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init() { }
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
                line: 7,
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
  }
}

#endif
