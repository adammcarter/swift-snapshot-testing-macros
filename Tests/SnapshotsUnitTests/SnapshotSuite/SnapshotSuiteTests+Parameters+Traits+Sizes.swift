#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Sizes {

    @Test
    func testWidthAndHeight() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(width: .minimum, height: .minimum))
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
                  traits: [.sizes(width: .minimum, height: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
    func testWidth() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(width: .minimum))
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
                  traits: [.sizes(width: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
    func testHeight() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(height: .minimum))
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
                  traits: [.sizes(height: .minimum), .theme(.all), .strategy(.image), .record(false)],
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
    func testLength() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.sizes(.minimum))
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
                  traits: [.sizes(.minimum), .theme(.all), .strategy(.image), .record(false)],
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
