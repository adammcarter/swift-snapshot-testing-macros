import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterCoreTests {
  @Test
  func rewritesSimpleSuiteAndNamedTest() throws {
    let input = """
    @Suite
    @SnapshotSuite(.sizes(.minimum))
    struct ProfileCardSnapshots {
      @SnapshotTest("Default")
      func profileCard() -> some View {
        return ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Suite(.sizes(.minimum))"))
    #expect(result.output.contains("@Test(\"Default\")"))
    #expect(!result.output.contains("-> some View"))
    #expect(result.output.contains("let snapshotValue = ProfileCard()"))
    #expect(result.output.contains("#expectSnapshot(snapshotValue, named: \"Default\")"))
    #expect(result.reasons.isEmpty)
    #expect(result.changed)
  }

  @Test
  func reportsUnsupportedSignatureShapeWhenNonParameterizedFunctionHasParameters() throws {
    let input = """
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard(state: UserState) -> some View {
        return ProfileCard(state: state)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-signature-shape" }))
    #expect(result.output.contains("@SnapshotTest"))
    #expect(!result.output.contains("@Test"))
  }
}
