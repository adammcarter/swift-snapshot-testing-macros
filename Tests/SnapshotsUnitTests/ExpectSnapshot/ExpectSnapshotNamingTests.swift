import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotNamingTests {
  @Test
  func explicitNameWinsOverBaseName() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
  }
}
