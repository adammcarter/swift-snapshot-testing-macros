#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests.Configurations {

  @Suite
  struct Init {

    @Test
    func testInitPassesConfigurationWhenInitWithConfiguration() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init(configuration: SnapshotConfiguration<String>) {

          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
              SnapshotConfiguration(name: "Config2", value: "2"),
            ]
          )
          func makeMyView(value: String) -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init(configuration: SnapshotConfiguration<String>) {

          }
          func makeMyView(value: String) -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 9,
                column: 3
              )
            }
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                  SnapshotConfiguration(name: "Config2", value: "2"),
                ]))
            func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testInitPassesConfigurationWhenInitWithConfigurationButDifferentArgName() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init(gfds: SnapshotConfiguration<String>) {

          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
              SnapshotConfiguration(name: "Config2", value: "2"),
            ]
          )
          func makeMyView(value: String) -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init(gfds: SnapshotConfiguration<String>) {

          }
          func makeMyView(value: String) -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 9,
                column: 3
              )
            }
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                  SnapshotConfiguration(name: "Config2", value: "2"),
                ]))
            func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testInitIgnoresConfigurationWhenEmptyInit() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init() {

          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
              SnapshotConfiguration(name: "Config2", value: "2"),
            ]
          )
          func makeMyView(value: String) -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init() {

          }
          func makeMyView(value: String) -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 9,
                column: 3
              )
            }
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                  SnapshotConfiguration(name: "Config2", value: "2"),
                ]))
            func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
              )
            }
          }
        }
        """
      }
    }

    @Test
    func testInitIgnoresConfigurationWhenInitWithWrongType() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        class SnapshotTests {
          init(configuration: String) {

          }

          @SnapshotTest(
            configurations: [
              SnapshotConfiguration(name: "Config1", value: "1"),
              SnapshotConfiguration(name: "Config2", value: "2"),
            ]
          )
          func makeMyView(value: String) -> some View {
            Text("my view")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        class SnapshotTests {
          init(configuration: String) {

          }
          func makeMyView(value: String) -> some View {
            Text("my view")
          }

          enum __generator_container_makeMyView {
            @MainActor
            static func makeGenerator(configuration: SnapshotConfiguration<(String)>) -> SnapshotTestingMacros.SnapshotGenerator<(String)> {
              SnapshotTestingMacros.SnapshotGenerator(
                displayName: "makeMyView",
                traits: [.theme(.all), .strategy(.image), .sizes(.minimum), .record(false)],
                configuration: configuration,
                makeValue: {
                  SnapshotTests().makeMyView(value: $0)
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 9,
                column: 3
              )
            }
          }

          @MainActor
          @Suite
          struct _GeneratedSnapshotSuite {

            @MainActor
            @Test(arguments: SnapshotTestingMacros.SnapshotConfigurationParser.parse([
                  SnapshotConfiguration(name: "Config1", value: "1"),
                  SnapshotConfiguration(name: "Config2", value: "2"),
                ]))
            func assertSnapshotMakeMyView(configuration: SnapshotConfiguration<(String)>) async throws {
              try await SnapshotTestingMacros.assertSnapshot(
                generator: __generator_container_makeMyView.makeGenerator(configuration: configuration)
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
