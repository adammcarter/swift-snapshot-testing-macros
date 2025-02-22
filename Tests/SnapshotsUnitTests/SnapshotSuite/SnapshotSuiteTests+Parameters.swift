#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotSuiteTests {
  @Suite
  struct Parameters {}
}

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
                      line: #line,
                      column: #column
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

extension SnapshotSuiteTests.Parameters {
  @Suite
  struct Traits {}
}

extension SnapshotSuiteTests.Parameters.Traits {
  @Test
  func testSingle() {
    assertMacro {
      """
      @MainActor
      @Suite
      @SnapshotSuite(.sizes(devices: .iPhoneX))
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
                      traits: [.sizes(devices: .iPhoneX), .theme(.all), .strategy(.image), .record(false)],
                      configuration: .none,
                      makeValue: {
                          MySuite().makeMyView()
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
  func testMany() {
    assertMacro {
      """
      @MainActor
      @Suite
      @SnapshotSuite(.sizes(devices: .iPhoneX), .theme(.light))
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
                      traits: [.sizes(devices: .iPhoneX), .theme(.light), .strategy(.image), .record(false)],
                      configuration: .none,
                      makeValue: {
                          MySuite().makeMyView()
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
  func testDefaultTraits() {
    assertMacro {
      """
      @MainActor
      @Suite
      @SnapshotSuite
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
              @Test()
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
  func testInheritingTraitsWhenConfigurations() {
    assertMacro {
      """
      @MainActor
      @Suite
      @SnapshotSuite(.record)
      struct MySuite {
          @SnapshotTest(configurations: [
              SnapshotConfiguration(name: "1", value: 1),
              SnapshotConfiguration(name: "2", value: 2),
          ])
          func makeView(value: Int) -> some View {
              Text("input")
          }
      }
      """
    } expansion: {
      """
      @MainActor
      @Suite
      struct MySuite {
          @SnapshotTest(configurations: [
              SnapshotConfiguration(name: "1", value: 1),
              SnapshotConfiguration(name: "2", value: 2),
          ])
          func makeView(value: Int) -> some View {
              Text("input")
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                      SnapshotConfiguration(name: "1", value: 1),
                      SnapshotConfiguration(name: "2", value: 2),
                  ]))
              func assertSnapshotMakeView(configuration: SnapshotConfiguration<(Int)>) async throws {
                  let generator = SnapshotTestingMacros.SnapshotGenerator(
                      displayName: "makeView",
                      traits: [.record(true), .theme(.all), .strategy(.image), .sizes(.minimum)],
                      configuration: configuration,
                      makeValue: {
                          MySuite().makeView(value: $0)
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

extension SnapshotSuiteTests.Parameters.Traits {
  @Suite
  struct BackgroundColor {

    @Test
    func testDefault() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MySnapshots {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
            @SnapshotTest
            func makeView() -> some View {
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
                            MySnapshots().makeView()
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
    func testSettingColor() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
            .backgroundColor(.red)
        )
        struct MySnapshots {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySnapshots {
            @SnapshotTest
            func makeView() -> some View {
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
                        traits: [.backgroundColor(.red), .theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            MySnapshots().makeView()
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

extension SnapshotSuiteTests.Parameters.Traits {
  @Suite
  struct Bug {

    @Test
    func testURL() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
            .bug("https://bugs.swift.org/browse/some-bug")
        )
        struct URL {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct URL {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
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
                            URL().makeView()
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
    func testTitle() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
            .bug("https://bugs.swift.org/browse/some-bug", "A title")
        )
        struct Title {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct Title {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.bug("https://bugs.swift.org/browse/some-bug", "A title"))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            Title().makeView()
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
    func testID() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(
            .bug(id: "some id")
        )
        struct ID {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct ID {
            @SnapshotTest
            func makeView() -> some View {
                Text("")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.bug(id: "some id"))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            ID().makeView()
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

extension SnapshotSuiteTests.Parameters.Traits {
  @Suite
  struct Condition {}
}

extension SnapshotSuiteTests.Parameters.Traits.Condition {
  @Suite
  struct Enabled {

    @Test
    func testEnabledIf() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled(if: false))
        struct EnabledIf {
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
        struct EnabledIf {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.enabled(if: false))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            EnabledIf().makeView()
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
    func testEnabledIfWithComment() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled(if: enableTests, "Some comment"))
        struct EnabledIfWithComment {
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
        struct EnabledIfWithComment {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.enabled(if: enableTests, "Some comment"))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            EnabledIfWithComment().makeView()
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
    func testEnabledWithCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled { false })
        struct EnabledWithCondition {
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
        struct EnabledWithCondition {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.enabled {
                    false
                })
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            EnabledWithCondition().makeView()
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
    func testEnabledWithCommentAndCondition() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.enabled("Some comment", { enableTests }))
        struct EnabledWithCommentAndCondition {
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
        struct EnabledWithCommentAndCondition {
            @SnapshotTest
            func makeView() -> some View {
                Text("input")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

                @MainActor
                @Test(.enabled("Some comment", {
                        enableTests
                    }))
                func assertSnapshotMakeView() async throws {
                    let generator = SnapshotTestingMacros.SnapshotGenerator(
                        displayName: "makeView",
                        traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                        configuration: .none,
                        makeValue: {
                            EnabledWithCommentAndCondition().makeView()
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

extension SnapshotSuiteTests.Parameters.Traits.Condition {
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

extension SnapshotSuiteTests.Parameters.Traits.Condition {
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

extension SnapshotSuiteTests.Parameters.Traits.Condition {
  @Suite
  struct TimeLimit {

    @Test
    func testTimeLimit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite(.timeLimit(.minutes(1)))
        struct TimeLimit {
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
        struct TimeLimit {
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
                            TimeLimit().makeView()
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

extension SnapshotSuiteTests.Parameters.Traits.Condition {
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
#endif
