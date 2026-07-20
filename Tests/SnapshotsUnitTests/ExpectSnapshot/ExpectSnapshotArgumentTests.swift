import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotArgumentTests {
  @Test
  func derivedArgumentNameUsesExistingNormalizationRules() {
    #expect(DerivedSnapshotNames.argumentName(from: "Two Words") == "Two-Words")
  }

  @Test
  func emptyDerivedArgumentNameFallsBackToSnapshot() {
    #expect(DerivedSnapshotNames.argumentName(from: "!!!") == "snapshot")
  }
}
