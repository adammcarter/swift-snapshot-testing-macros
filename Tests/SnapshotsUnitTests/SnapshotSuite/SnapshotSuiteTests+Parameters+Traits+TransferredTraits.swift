#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct TransferredTraits {

    @Test
    func testBug() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
            .bug("https://bugs.swift.org/browse/some-bug")
        )
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
              @Test(.bug("https://bugs.swift.org/browse/some-bug"))
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
                  line: 7,
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
    func testEnabled() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled(if: true))
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
              @Test(.enabled(if: true))
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
    func testDisabled() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.disabled(if: true))
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
              @Test(.disabled(if: true))
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
    func testTimeLimit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.timeLimit(.minutes(1)))
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
              @Test(.timeLimit(.minutes(1)))
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
                  column: 5
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
