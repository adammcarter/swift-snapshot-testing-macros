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
    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.reasons.isEmpty)
    #expect(result.changed)
  }

  @Test
  func addsMainActorToSwiftUISuiteAndTopLevelSnapshotTests() throws {
    let input = """
    @SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotTest("Inside")
      func profileCard() -> some View {
        ProfileCard()
      }
    }

    @SnapshotTest("Top level")
    func standAloneCard() -> some View {
      ProfileCard()
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@MainActor\n@Suite\nstruct ProfileSnapshots"))
    #expect(result.output.contains("@MainActor\n@Test(\"Top level\")"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func keepsSingleSuiteAttributeWhenLegacySuiteIsBare() throws {
    let input = """
    @Suite
    @SnapshotSuite
    struct BasicSnapshots {
      @SnapshotTest
      func card() -> some View {
        ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.output.contains("@Test"))
    #expect(result.reasons.isEmpty)
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

    #expect(result.output.contains("@MainActor\n@Suite\nstruct CompareAdvertButtonSnapshotTests"))
    #expect(result.output.contains("@MainActor"))
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
