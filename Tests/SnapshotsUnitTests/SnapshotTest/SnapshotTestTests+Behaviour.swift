#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

  @Suite
  struct Behaviour {

    @Test
    func testInheritingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ],
                behaviour: .inheritingConfigurations
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "2", value: 2),
                      ]))
              func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "aTest",
                  traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().aTest(value: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 10,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """#
      }
    }

    @Test
    func testReplacingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ],
                behaviour: .replacingConfigurations
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "2", value: 2),
                      ]))
              func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "aTest",
                  traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().aTest(value: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 10,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """#
      }
    }

    @Test
    func testDefaultValueIsReplacingConfigurations() {
      assertMacro {
        #"""
        @MainActor
        @Suite
        @SnapshotSuite(
            .theme(.dark),
            configurations: [
                SnapshotConfiguration(name: "1", value: 1),
            ]
        )
        struct SnapshotTests {
            @SnapshotTest(
                .theme(.light),
                configurations: [
                    SnapshotConfiguration(name: "2", value: 2),
                ]
            )
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }
        }
        """#
      } expansion: {
        #"""
        @MainActor
        @Suite
        struct SnapshotTests {
            func aTest(value: Int) -> some View {
                Text("\(value)")
            }

            @MainActor
            @Suite
            struct _GeneratedSnapshotSuite {

              @MainActor
              @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                          SnapshotConfiguration(name: "2", value: 2),
                      ]))
              func assertSnapshotATest(configuration: SnapshotConfiguration<(Int)>) async throws {
                let generator = SnapshotTestingMacros.SnapshotGenerator(
                  displayName: "aTest",
                  traits: [.theme(.light), .strategy(.image), .sizes(.minimum), .record(false)],
                  configuration: configuration,
                  makeValue: {
                      SnapshotTests().aTest(value: $0)
                  },
                  fileID: #fileID,
                  filePath: #filePath,
                  line: 10,
                  column: 5
                )

                try await SnapshotTestingMacros.assertSnapshot(generator: generator)
              }
            }
        }
        """#
      }
    }
  }
}
#endif
