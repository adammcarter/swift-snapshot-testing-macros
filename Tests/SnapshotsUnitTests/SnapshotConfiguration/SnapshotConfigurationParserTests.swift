import Foundation
import Testing

@testable import SnapshotTestingMacros

struct SnapshotConfigurationParserTests {

  @Test
  func parseFloatingPointSequenceUsesFormattedNamesByDefault() {
    let values = stride(from: 0.0, to: 0.31, by: 0.1)
    let configurations = SnapshotConfigurationParser.parse(values)

    #expect(configurations.map(\.name) == ["0", "0.1", "0.2", "0.3"])
    #expect(configurations.map(\.value) == Array(values))
  }

  @Test
  func parseFloatingPointClosureUsesFormattedNamesByDefault() {
    let values = [0.1 + 0.2]
    let configurations = SnapshotConfigurationParser.parse { values }

    #expect(configurations.map(\.name) == ["0.3"])
    #expect(configurations.map(\.value) == values)
  }

  @Test
  func parseFloatingPointCanUseCustomNameTransform() {
    let values = [0.1 + 0.2]
    let configurations = SnapshotConfigurationParser.parse(
      values,
      configurationNameTransform: { "\($0)" }
    )

    #expect(configurations.map(\.name) == ["0.30000000000000004"])
    #expect(configurations.map(\.value) == values)
  }

  @Test
  func parseNonFloatingPointKeepsStringInterpolationNames() {
    let values = [1_000]
    let configurations = SnapshotConfigurationParser.parse(values)

    #expect(configurations.map(\.name) == ["1000"])
    #expect(configurations.map(\.value) == values)
  }

  @Test
  func parseNonFloatingPointSequence() {
    let values = stride(from: 1, through: 3, by: 1)
    let configurations = SnapshotConfigurationParser.parse(values)

    #expect(configurations.map(\.name) == ["1", "2", "3"])
    #expect(configurations.map(\.value) == Array(values))
  }
}
