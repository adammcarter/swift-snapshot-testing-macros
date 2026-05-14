import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotAdapterTests {
  @Test
  func displayNamePrefersExplicitName() {
    let displayName = ExpectSnapshotAdapter.displayName(named: "custom-name", baseName: "myTest")

    #expect(displayName == "custom-name")
  }
}
