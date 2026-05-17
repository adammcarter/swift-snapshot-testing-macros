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

  @Test
  func rewritesNonParameterizedBodyWithSetupStatements() throws {
    let input = """
    @SnapshotSuite
    struct CompareAdvertButtonSnapshotTests {
      @SnapshotTest
      func highlighted() -> UIView {
        let button = CompareAdvertButton()
        button.isHighlighted = true

        return button
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test"))
    #expect(!result.output.contains("-> UIView"))
    #expect(result.output.contains("let button = CompareAdvertButton()"))
    #expect(result.output.contains("button.isHighlighted = true"))
    #expect(result.output.contains("let snapshotValue = button"))
    #expect(result.output.contains("#expectSnapshot(snapshotValue)"))
    #expect(result.reasons.isEmpty)
    #expect(result.changed)
  }

  @Test
  func skipsNonParameterizedRewriteWhenPreludeContainsEarlyReturn() throws {
    let input = """
    @SnapshotSuite
    struct ConditionalSnapshots {
      @SnapshotTest
      func conditional() -> UIView {
        if Bool.random() {
          return PlaceholderView()
        }

        return FinalView()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-signature-shape" }))
    #expect(result.output.contains("@SnapshotTest"))
    #expect(!result.output.contains("@Test"))
  }
}
