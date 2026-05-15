import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotConfigurationTests {
  @Test
  func namedConfigurationUsesItsNameForTheSnapshotFolder() {
    let configuration = SnapshotConfiguration(name: "logged-out", value: "guest")

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "logged-out")
  }

  @Test
  func unnamedConfigurationDerivesANormalizedFolderName() {
    let configuration = SnapshotConfiguration(name: nil, value: "Two Words")

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "Two-Words")
  }

  @Test
  func emptyDerivedConfigurationNameFallsBackToSnapshot() {
    let configuration = SnapshotConfiguration(name: nil, value: "!!!")

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "snapshot")
  }
}
