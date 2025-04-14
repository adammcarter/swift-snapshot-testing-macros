#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters {

  @Suite
  struct Name {

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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func assertSnapshotMakeMyView() async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "Some name",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: .none,
                  makeValue: {
                      MySuite().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func assertSnapshotMakeMyView() async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "Some name",
                  traits: [.record(true), .theme(.all), .strategy(.image), .sizes(.minimum)],
                  configuration: .none,
                  makeValue: {
                      MySuite().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func assertSnapshotMakeMyView() async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: .none,
                  makeValue: {
                      MySuite().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            @SnapshotTest
            func makeMyView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test()
              func assertSnapshotMakeMyView() async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "makeMyView",
                  traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: .none,
                  makeValue: {
                      MySuite().makeMyView()
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 5,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """
      }
    }

    @Test
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
          @SnapshotTest(
            "Closure",
            configurationValues: { [1, 2] }
          )
          func testClosure(value: Int) -> some View {
            Text("value: \(value)")
          }
        #endif

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            #if swift(>=6.1)
            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse({
                [1, 2]
              }))
            func assertSnapshotTestClosure(configuration: SnapshotConfiguration<(Int)>) async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "Closure",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  MySuite().testClosure(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 6,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
