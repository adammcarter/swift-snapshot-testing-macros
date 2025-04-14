#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits.Condition {

  @Suite
  struct Disabled {

    @Test
    func testDisabled() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled())
        struct MySuite {
          @SnapshotTest
          func makeView() -> some View {
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
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled())
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  MySuite().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDisabledWithComment() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled("Some comment"))
        struct DisabledWithComment {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct DisabledWithComment {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled("Some comment"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  DisabledWithComment().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDisabledIf() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled(if: true))
        struct DisabledIf {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct DisabledIf {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled(if: true))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  DisabledIf().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDisabledIfWithComment() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled(if: !enableTests, "Some comment"))
        struct DisabledIfWithComment {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct DisabledIfWithComment {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled(if: !enableTests, "Some comment"))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  DisabledIfWithComment().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDisabledWithCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled(if: true))
        struct DisabledWithCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct DisabledWithCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled(if: true))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  DisabledWithCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }

    @Test
    func testDisabledWithCommentAndCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled("Some comment", { !enableTests }))
        struct DisabledWithCommentAndCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct DisabledWithCommentAndCondition {
          @SnapshotTest
          func makeView() -> some View {
            Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(.disabled("Some comment", {
                !enableTests
              }))
            func assertSnapshotMakeView() async throws {
              let generator = SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: .none,
                makeValue: {
                  DisabledWithCommentAndCondition().makeView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )

              try await SnapshotTestingMacros.assertSnapshot(generator: generator)
            }
          }
        }
        """
      }
    }
  }
}
#endif
