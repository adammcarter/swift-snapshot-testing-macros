import Testing

@testable import SnapshotTestingMacros

private enum TupleLayout: Sendable {
  case compact
}

private enum TupleUserState: Sendable {
  case loggedIn
}

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

  @Test
  func unnamedTuple2ConfigurationDerivesPerElementNamesWithoutTypeQualification() {
    let configuration = SnapshotConfiguration(
      name: nil,
      value: (TupleLayout.compact, TupleUserState.loggedIn)
    )

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "compact-loggedIn")
  }

  @Test
  func unnamedTuple3ConfigurationDerivesPerElementNamesWithoutTypeQualification() {
    let configuration = SnapshotConfiguration(
      name: nil,
      value: (TupleLayout.compact, TupleUserState.loggedIn, 2)
    )

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "compact-loggedIn-2")
  }

  @Test
  func namedTupleConfigurationKeepsItsExplicitName() {
    let configuration = SnapshotConfiguration(
      name: "explicit",
      value: (TupleLayout.compact, TupleUserState.loggedIn)
    )

    #expect(ExpectSnapshotAdapter.configurationName(for: configuration) == "explicit")
  }
}
