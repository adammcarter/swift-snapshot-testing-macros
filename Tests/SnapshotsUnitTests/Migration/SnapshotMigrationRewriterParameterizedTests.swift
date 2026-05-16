import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterParameterizedTests {
  @Test
  func rewritesSwiftUIConfigurationsToSnapshotConfigurationForm() throws {
    let input = """
    @SnapshotTest(configurations: makeStates())
    func profile(state: UserState) -> some View {
      UserProfileView(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(arguments: makeStates())"))
    #expect(result.output.contains("func profile(configuration: SnapshotConfiguration<UserState>)"))
    #expect(result.output.contains("#expectSnapshot(configuration) { state in"))
    #expect(result.output.contains("UserProfileView(state: state)"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesUIKitConfigurationUsingDirectValueAndNamedArtifacts() throws {
    let input = """
    @SnapshotTest("Card", configurations: makeCases())
    func card(state: CardState) -> UIViewController {
      makeController(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(\"Card\", arguments: makeCases())"))
    #expect(result.output.contains("func card(configuration: SnapshotConfiguration<CardState>)"))
    #expect(result.output.contains("let state = configuration.value"))
    #expect(result.output.contains("let snapshotValue = makeController(state: state)"))
    #expect(result.output.contains("#expectSnapshot(snapshotValue, named:"))
    #expect(result.output.contains("Card"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesSwiftUIConfigurationValuesUsingArgumentBuilder() throws {
    let input = """
    @SnapshotTest(configurationValues: makeStates())
    func profile(state: UserState) -> some View {
      UserProfileView(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(arguments: makeStates())"))
    #expect(result.output.contains("func profile(state: UserState)"))
    #expect(result.output.contains("#expectSnapshot(argument: state) { state in"))
    #expect(result.output.contains("UserProfileView(state: state)"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func preservesPrecomputedConfigurationValuesExpression() throws {
    let input = """
    @SnapshotTest(configurationValues: states)
    func profile(state: UserState) -> some View {
      UserProfileView(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(arguments: states)"))
    #expect(!result.output.contains("@Test(arguments: states())"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func skipsUIKitConfigurationValuesWithoutStableArgumentNaming() throws {
    let input = """
    @SnapshotTest(configurationValues: makeStates())
    func card(state: CardState) -> UIViewController {
      makeController(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-argument-naming" }))
    #expect(result.output.contains("@SnapshotTest(configurationValues: makeStates())"))
    #expect(!result.output.contains("@Test(arguments: makeStates())"))
  }
}
