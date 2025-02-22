#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotSuiteTests {
  @Suite
  struct FunctionModifiers {}
}

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct Scope {

    @Test
    func testStatic() {
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
            @SnapshotTest
            static func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests.makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testNonStatic() {
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
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct Enum {
    @Test
    func testStaticFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        enum MyEnum {
            @SnapshotTest
            static func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        enum MyEnum {
            @SnapshotTest
            static func makeView() -> some View {
                Text("")
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
                            MyEnum.makeView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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
            @SnapshotTest
            func makeMyView() async -> some View {
                Text("my view")
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
                            await SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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
            @SnapshotTest
            static func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests.makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testAsyncInit() {
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
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
            init() async { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            await SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
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

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct Throws {

    @Test
    func testThrowingFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() throws -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() throws -> some View {
                Text("my view")
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
                            try SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testNonThrowingFunction() {
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
            @SnapshotTest
            static func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests.makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testThrowingInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() throws { }

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
            init() throws { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            try SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testNonThrowingInit() {
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

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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

extension SnapshotSuiteTests.FunctionModifiers {
  @Suite
  struct AsyncThrows {

    @Test
    func testFunction() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() async throws -> some View {
                Text("my view")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
            @SnapshotTest
            func makeMyView() async throws -> some View {
                Text("my view")
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
                            try await SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
                    )

                    try await SnapshotTestingMacros.assertSnapshot(generator: generator)
                }
            }
        }
        """
      }
    }

    @Test
    func testInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
            init() async throws { }

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
            init() async throws { }

            @SnapshotTest
            func makeMyView() -> some View {
                Text("my view")
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
                            try await SnapshotTests().makeMyView()
                        },
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: #column
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
