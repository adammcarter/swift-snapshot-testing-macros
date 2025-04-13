#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters.Traits {

  @Suite
  struct Padding {

    @Test
    func testEdgesAndLength() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding(.all, 20.0))
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
                        traits: [.padding(.all, 20.0), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
    func testEdges() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding(.all))
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
                        traits: [.padding(.all), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
        @SnapshotSuite(.padding(20.0))
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
                        traits: [.padding(20.0), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
    func testEmpty() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding())
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
                        traits: [.padding(), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
    func testProperty() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding)
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
                        traits: [.padding, .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
    func testInheritingPadding() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.padding)
        struct Tags {
            @SnapshotTest(.padding(20))
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
            @SnapshotTest(.padding(20))
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
                        traits: [.padding(20), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
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
