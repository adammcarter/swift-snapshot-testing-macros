#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite(
    .disabled("Current limitation on recursive macro expansion.")
  )
  struct Subsuite {

    @Test
    func test() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
            }

            struct SubOne {
                @SnapshotTest
                func makeChildView() -> some View {
                    Text("child view")
                }
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            func makeMyView() -> some View {
                Text("my view")
            }
            @MainActor @Suite

            struct SubOne {
                func makeChildView() -> some View {
                    Text("child view")
                }

                @MainActor
                @Suite
                struct _GeneratedSnapshotSuite {

                    @MainActor
                    @Test(.tags(.snapshots))
                    func assertSnapshotMakeChildView() async throws {
                        let generator = SnapshotGenerator(
                            displayName: "makeChildView",
                            traits: [
                          .theme(.all),
                          .sizes(devices: .iPhoneX, fitting: .widthAndHeight),
                          .record(false),
                        ],
                            configuration: .none,
                            makeValue: {
                                SubOne.makeChildView()
                            }
                        )

                        await __assertSnapshot(generator: generator)
                    }
                }
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.tags(.snapshots))
                func assertSnapshotMakeMyView() async throws {
                    let generator = SnapshotGenerator(
                        displayName: "makeMyView",
                        traits: [
                      .theme(.all),
                      .sizes(devices: .iPhoneX, fitting: .widthAndHeight),
                      .record(false),
                    ],
                        configuration: .none,
                        makeValue: {
                            SnapshotTests.makeMyView()
                        }
                    )

                    await __assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testWithMix() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            struct SubOne {
                @SnapshotTest
                func makeMyView() -> some View {
                    Text("my view")
                }
            }

            @MainActor
            @Suite
            @SnapshotSuite
            struct SubTwo {
                @SnapshotTest
                func makeAnotherView() -> some View {
                    Text("another view")
                }
            }
        }
        """
      }
    }

    @Test
    func testWithArguments() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.record(true))
        struct SnapshotTests {
            struct SubOne {
                @SnapshotTest
                func makeMyView() -> some View {
                    Text("my view")
                }
            }
        }
        """
      }
    }
  }
}
#endif
