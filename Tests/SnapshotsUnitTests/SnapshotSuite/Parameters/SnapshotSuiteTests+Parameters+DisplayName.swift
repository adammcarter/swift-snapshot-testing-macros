#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters {

  @Suite
  struct DisplayName {

    @Test
    func testPopulated() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Some name")
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "Some name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
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
          struct MySuite_GeneratedSnapshotSuite {

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
    func testPopulatedWithTraits() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Some name", .record)
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "Some name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots, SnapshotTestingMacros.__SuiteTraitBox(.record).wrapped)
          struct MySuite_GeneratedSnapshotSuite {

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
    func testEmpty() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("")
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "",
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
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
          struct MySuite_GeneratedSnapshotSuite {

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
    func testMissing() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
          @SnapshotTest
          func makeMyView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeMyView() -> some View {
            Text("input")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "makeMyView",
                configuration: configuration,
                makeValue: {
                  MySuite().makeMyView()
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
          struct MySuite_GeneratedSnapshotSuite {

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

    @Test(.disabled("Doesn't work with #if config"))
    func testDisplayNameInIfConfig() {
      assertMacro {
        #"""
        @Suite
        @SnapshotSuite
        struct MySuite {
        #if swift(>=6.1)
          // Closures inside macros have a compiler bug prior to Swift 6.1
          @SnapshotTest(
            "Closure",
            configurationValues: { [1, 2] }
          )
          func testClosure(value: Int) -> some View {
            Text("value: \(value)")
          }
        #endif
        }
        """#
      } expansion: {
        #"""
        @Suite
        struct MySuite {
        #if swift(>=6.1)
          // Closures inside macros have a compiler bug prior to Swift 6.1
          func testClosure(value: Int) -> some View {
            Text("value: \(value)")
          }
        #endif

          @MainActor
          @Suite(.snapshots)
          struct _GeneratedSnapshotSuite {

            #if swift(>=6.1)
            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse({
                [1, 2]
              }))
            func assertSnapshotTestClosure(configuration: SnapshotConfiguration<(Int)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_testClosure.makeGenerator(configuration: configuration)
              )
            }
            #endif
          }
        }
        """#
      }
    }
  }
}
#endif
