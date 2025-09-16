#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests.Parameters {

  @Suite
  struct DisplayName {

    @Test
    func testPopulatedString() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
          @SnapshotTest("Some name")
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "Some name",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
          @Suite(.snapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testEmptyString() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySuite {
          @SnapshotTest("")
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
          @Suite(.snapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testNoName() {
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
          @Suite(.snapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testInheritName() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Suite name")
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "Suite name",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
          @Suite(.snapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testBothNames() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Suite name")
        struct MySuite {
          @SnapshotTest("Test name")
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
            static func makeGenerator(configuration: SnapshotConfiguration<Void>) -> SnapshotTestingMacros.SnapshotGenerator<Void> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "Test name",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
          @Suite(.snapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeMyView_snapshotTest() async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: .none)
              )
            }
          }
        }
        """
      }
    }
  }
}
#endif
