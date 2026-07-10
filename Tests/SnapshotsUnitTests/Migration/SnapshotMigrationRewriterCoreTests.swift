import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterCoreTests {
  @Test
  func moduleQualifiedAttributesProduceSkipReasonInsteadOfSilentNoChange() throws {
    let input = """
    @SnapshotsModule.SnapshotSuite
    struct ProfileSnapshots {
      @SnapshotsModule.SnapshotTest("Default")
      func profileCard() -> some View {
        ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(!result.changed)
    let qualifiedReasons = result.reasons.filter { $0.code == "qualified-attribute-unsupported" }
    #expect(qualifiedReasons.count == 2)
    #expect(qualifiedReasons.map(\.line) == [1, 3])
  }

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
  func dedupingSuiteAttributesKeepsAdjacentAttributeLinesTogether() throws {
    let input = """
    @MainActor
    @Suite
    @SnapshotSuite(.theme(.light))
    struct BasicSnapshots {
      @SnapshotTest
      func card() -> some View {
        ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(
      result.output.contains(
        """
        @MainActor
        @Suite(.theme(.light))
        struct BasicSnapshots
        """
      )
    )
    #expect(!result.output.contains("@MainActor\n\n@Suite"))
    expectParsesCleanly(result.output)
  }

  @Test
  func preservesExistingSuiteArgumentsWhenDedupingAgainstSnapshotSuite() throws {
    let input = """
    @Suite("Profile cards", .serialized)
    @SnapshotSuite(.theme(.light))
    struct ProfileCardSnapshots {
      @SnapshotTest("Default")
      func profileCard() -> some View {
        ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Suite(\"Profile cards\", .serialized, .theme(.light))"))
    #expect(!result.output.contains("@SnapshotSuite"))
    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.output.contains("@Test(\"Default\")"))
    #expect(result.reasons.isEmpty)
    #expect(result.changed)
    expectParsesCleanly(result.output)
  }

  @Test
  func deletesBareSnapshotSuiteWhenExistingSuiteHasArguments() throws {
    let input = """
    @Suite("Profile cards", .serialized)
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard() -> some View {
        ProfileCard()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Suite(\"Profile cards\", .serialized)\nstruct ProfileCardSnapshots"))
    #expect(!result.output.contains("@SnapshotSuite"))
    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func foldsSnapshotSuiteTraitsIntoExistingSuiteAndKeepsLegacyDisplayNameForArtifacts() throws {
    let input = """
    @Suite(.serialized)
    @SnapshotSuite("Suite Cards", .theme(.light))
    struct CardSuite {
      @SnapshotTest(configurations: [.init(name: "compact", value: 1)])
      func cards(state: Int) -> some View {
        CardView(state: state)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    // The user's own @Suite arguments win the attribute merge; the legacy display name is
    // not promoted (it never named the Swift Testing suite), but it must keep naming the
    // snapshot artifacts through the parameterized display-name fallback.
    #expect(result.output.contains("@Suite(.serialized, .theme(.light))"))
    #expect(!result.output.contains("@SnapshotSuite"))
    #expect(!result.output.contains("@Suite(\"Suite Cards\""))
    #expect(
      result.output.contains(
        #"#expectSnapshot(snapshotConfiguration, named: "Suite Cards") { _ in snapshotValue }"#
      )
    )
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func doesNotFoldNonLiteralLegacyDisplayNameAsSuiteTrait() throws {
    let input = """
    @Suite(.serialized)
    @SnapshotSuite(Self.suiteName, .theme(.light))
    struct CardSuite {
      @SnapshotTest
      func card() -> some View {
        CardView()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    // The non-literal first argument is the legacy display name (typed `String`/`String?` by the
    // overload), not a suite trait: only the real trait `.theme(.light)` may fold into `@Suite`.
    #expect(result.output.contains("@Suite(.serialized, .theme(.light))"))
    #expect(!result.output.contains("Self.suiteName"))
    #expect(!result.output.contains("@SnapshotSuite"))
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func foldsTraitsIntoSuiteArgumentListEndingInTrailingComma() throws {
    let input = """
    @Suite("Cards", .serialized,)
    @SnapshotSuite(.theme(.light))
    struct CardSuite {
      @SnapshotTest
      func card() -> some View {
        CardView()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Suite(\"Cards\", .serialized, .theme(.light))"))
    #expect(!result.output.contains(",,"))
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func foldsTraitsWhenSnapshotSuitePrecedesArgfulSuite() throws {
    let input = """
    @SnapshotSuite(.sizes(.minimum))
    @Suite("Cards")
    struct CardSuite {
      @SnapshotTest
      func card() -> some View {
        CardView()
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Suite(\"Cards\", .sizes(.minimum))"))
    #expect(!result.output.contains("@SnapshotSuite"))
    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
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
