#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Tags {

    @Test
    func testAddingTags() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.tags(.someTag))
        struct Tags {
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
        struct Tags {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.tags(.someTag))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            Tags().makeView()
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
    func testAddingReservedSnapshotsTag() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.tags(.snapshots))
        struct Tags {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }
        }
        """
      } diagnostics: {
        """

        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct Tags {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.tags(.snapshots))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            Tags().makeView()
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
    func testTagsDefault() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct Tags {
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
        struct Tags {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test()
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            Tags().makeView()
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
