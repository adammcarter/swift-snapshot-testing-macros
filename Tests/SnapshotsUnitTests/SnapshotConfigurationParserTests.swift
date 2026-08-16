import SnapshotTestingMacros
import Testing

/// The `configurationValues:` macro overloads accept any `Collection`, so the runtime parser
/// the generated code calls must accept any `Collection` too — not just `Array`.
@Suite
struct SnapshotConfigurationParserTests {

  @Test
  func parsesArrays() {
    let configurations = SnapshotConfigurationParser.parse([1, 2, 3])

    #expect(configurations.map(\.name) == ["1", "2", "3"])
    #expect(configurations.map(\.value) == [1, 2, 3])
  }

  @Test
  func parsesNonArrayCollections() {
    let configurations = SnapshotConfigurationParser.parse(1 ... 3)

    #expect(configurations.map(\.name) == ["1", "2", "3"])
    #expect(configurations.map(\.value) == [1, 2, 3])
  }

  @Test
  func parsesNonArrayCollectionClosures() {
    let configurations = SnapshotConfigurationParser.parse { 4 ... 5 }

    #expect(configurations.map(\.name) == ["4", "5"])
    #expect(configurations.map(\.value) == [4, 5])
  }

  @Test
  func parsesConfigurationArraysWithoutRewrapping() {
    let configurations = SnapshotConfigurationParser.parse([
      SnapshotConfiguration(name: "custom", value: "a")
    ])

    #expect(configurations.map(\.name) == ["custom"])
    #expect(configurations.map(\.value) == ["a"])
  }
}
