import Testing

@testable import SnapshotMigrationSupport

@Suite
struct RewriterParameterizedTests {
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
    #expect(result.output.contains("let snapshotConfiguration = configuration"))
    #expect(result.output.contains("let state = configuration.value"))
    #expect(result.output.contains("let snapshotValue = UserProfileView(state: state)"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"profile\") { _ in snapshotValue }"
      )
    )
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

    #expect(result.output.contains("@MainActor"))
    #expect(result.output.contains("@Test(\"Card\", arguments: makeCases())"))
    #expect(result.output.contains("func card(configuration: SnapshotConfiguration<CardState>)"))
    #expect(result.output.contains("let snapshotConfiguration = configuration"))
    #expect(result.output.contains("let state = configuration.value"))
    #expect(result.output.contains("let snapshotValue: UIViewController = makeController(state: state)"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"Card\") { _ in snapshotValue }"
      )
    )
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
    #expect(
      result.output.contains(
        #"let snapshotConfiguration = SnapshotConfiguration(name: "\(state)", value: state)"#
      )
    )
    #expect(result.output.contains("let snapshotValue = UserProfileView(state: state)"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"profile\") { _ in snapshotValue }"
      )
    )
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
  func rewritesUIKitConfigurationValuesWithoutExplicitLegacyName() throws {
    let input = """
    @SnapshotTest(configurationValues: makeStates())
    func card(state: CardState) -> UIViewController {
      makeController(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@MainActor"))
    #expect(result.output.contains("@Test(arguments: makeStates())"))
    #expect(result.output.contains("func card(state: CardState)"))
    #expect(result.output.contains("let snapshotValue: UIViewController = makeController(state: state)"))
    #expect(
      result.output.contains(
        #"let snapshotConfiguration = SnapshotConfiguration(name: "\(state)", value: state)"#
      )
    )
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"card\") { _ in snapshotValue }"
      )
    )
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesSwiftUIConfigurationsWhenArgumentsExpressionUsesMapClosure() throws {
    let input = """
    @SnapshotTest(
      configurations: Bool.allCases.map {
        .init(name: "signed \\($0 ? "in" : "out")", value: $0)
      }
    )
    func makeView(isSignedIn: Bool) -> some View {
      BrandView(isSignedIn: isSignedIn)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test("))
    #expect(result.output.contains("arguments: Bool.allCases.map"))
    #expect(result.output.contains("SnapshotConfiguration<Bool>(name:"))
    #expect(!result.output.contains(".init(name:"))
    #expect(result.output.contains("func makeView(configuration: SnapshotConfiguration<Bool>)"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func addsConfigurationTypeContextToLiteralConfigurationsWithoutNilValues() throws {
    let input = """
    @SnapshotSuite
    struct CoreListingViewSnapshotSpec {
      @SnapshotTest(configurations: [
        .init(name: "discount", value: Listing.CoreListingDiscount.basic),
        .init(name: "finance", value: Listing.CoreListingFinance.basic),
      ])
      func cell(listing: Listing) -> some View {
        CoreListingView(listing: listing)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("SnapshotConfiguration<Listing>(name: \"discount\""))
    #expect(result.output.contains("SnapshotConfiguration<Listing>(name: \"finance\""))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesParameterizedBodyWithSetupStatementsForSwiftUIConfigurations() throws {
    let input = """
    @SnapshotTest(configurations: styles)
    func populated(style: SignpostStyle) async throws -> some View {
      let viewModel = makeViewModel(style: style)
      viewModel.contentView = makeContentView()
      return Signpost(viewModel: viewModel)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(arguments: styles)"))
    #expect(result.output.contains("func populated(configuration: SnapshotConfiguration<SignpostStyle>) async throws"))
    #expect(result.output.contains("let snapshotConfiguration = configuration"))
    #expect(result.output.contains("let style = configuration.value"))
    #expect(result.output.contains("let viewModel = makeViewModel(style: style)"))
    #expect(result.output.contains("viewModel.contentView = makeContentView()"))
    #expect(result.output.contains("let snapshotValue = Signpost(viewModel: viewModel)"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"populated\") { _ in snapshotValue }"
      )
    )
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesAsyncParameterizedSwiftUIConfigurationsWithAwaitedSnapshotAssertion() throws {
    let input = """
    @SnapshotTest(configurations: methods)
    func code(method: DeliveryMethod) async -> some View {
      let model = await makeModel(method: method)
      return TwoFactorCodeView(viewModel: model)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("func code(configuration: SnapshotConfiguration<DeliveryMethod>) async"))
    #expect(result.output.contains("let snapshotConfiguration = configuration"))
    #expect(result.output.contains("let method = configuration.value"))
    #expect(result.output.contains("let snapshotValue = TwoFactorCodeView(viewModel: model)"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"code\") { _ in snapshotValue }"
      )
    )
    #expect(!result.output.contains("await #expectSnapshot("))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func invokesZeroArgConfigurationFactoryWhenArgumentsUseFunctionReference() throws {
    let input = """
    @SnapshotSuite
    struct AnchorBarSnapshotSuite {
      @SnapshotTest(configurations: makeConfigurations)
      func anchorBar(configuration: ([AnchorBar.Anchor], String?)) -> some View {
        AnchorBar(viewModel: .init(anchors: configuration.0, currentAnchor: configuration.1 ?? ""))
      }
    }

    private func makeConfigurations() -> [SnapshotConfiguration<([AnchorBar.Anchor], String?)>] {
      []
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@Test(arguments: makeConfigurations())"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func addsExplicitConfigurationTypeContextWhenLiteralArgumentsContainNilValues() throws {
    let input = """
    @SnapshotSuite
    struct ToggleSnapshotSuite {
      @SnapshotTest(configurations: [
        .init(name: "with text", value: ("text", false)),
        .init(name: "without text", value: (nil, true))
      ])
      func toggle(helpText: String?, isSelected: Bool) -> some View {
        Toggle("", isOn: .constant(isSelected))
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("SnapshotConfiguration<(String?, Bool)>(name: \"with text\""))
    #expect(result.output.contains("SnapshotConfiguration<(String?, Bool)>(name: \"without text\""))
    #expect(result.output.contains("as [SnapshotConfiguration<(String?, Bool)>]"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesOptionalLiteralConfigurationsWithTypedSnapshotConfigurationElements() throws {
    let input = """
    @SnapshotSuite
    struct ComponentViewControllerSnapshotTests {
      @SnapshotTest(configurations: [
        .init(name: "when scrolled to middle", value: ScrollAction(id: "middle")),
        .init(name: "when at top", value: nil),
      ])
      func component(scrollAction: ScrollAction?) -> UIViewController {
        makeController(scrollAction: scrollAction)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("SnapshotConfiguration<ScrollAction?>(name: \"when scrolled to middle\""))
    #expect(result.output.contains("SnapshotConfiguration<ScrollAction?>(name: \"when at top\""))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func avoidsShadowingSnapshotConfigurationWhenLegacyParameterIsNamedConfiguration() throws {
    let input = """
    @SnapshotSuite
    struct FullPageAdvertPrimaryActionsViewSnapshotTests {
      @SnapshotTest(configurations: makeConfigurations())
      func allActions(configuration: FullPageAdvertPrimaryActionsConfiguration) -> UIView {
        makeView(configuration: configuration)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    // The configuration must be captured before the extracted value shadows the
    // `configuration` parameter name.
    #expect(result.output.contains("let snapshotConfiguration = configuration\n"))
    #expect(result.output.contains("let configuration = configuration.value"))
    #expect(
      result.output.contains(
        "#expectSnapshot(snapshotConfiguration, named: \"allActions\") { _ in snapshotValue }"
      )
    )
    let captureIndex = try #require(result.output.range(of: "let snapshotConfiguration = configuration\n"))
    let shadowIndex = try #require(result.output.range(of: "let configuration = configuration.value"))
    #expect(captureIndex.lowerBound < shadowIndex.lowerBound)
    #expect(result.reasons.isEmpty)
  }

  @Test
  func preservesUIKitReturnTypeAsSnapshotValueTypeContextForParameterizedMigrations() throws {
    let input = """
    @SnapshotSuite
    struct MyCarReminderSettingsHeaderViewSnapshotTests {
      @SnapshotTest(configurations: [
        .init(name: "frequency", value: 0),
        .init(name: "activation", value: 1),
      ])
      func view(section: UInt) throws -> UIView {
        MyCarReminderSettingsHeaderView(section: section)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.output.contains("@MainActor"))
    #expect(result.output.contains("let snapshotValue: UIView = MyCarReminderSettingsHeaderView(section: section)"))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func keepsSingleSuiteAttributeForParameterizedMigration() throws {
    let input = """
    @Suite
    @SnapshotSuite(.sizes(.minimum))
    struct BrandViewSnapshotTests {
      @SnapshotTest(
        configurations: Bool.allCases.map {
          .init(name: "signed \\($0 ? "in" : "out")", value: $0)
        }
      )
      func makeView(isSignedIn: Bool) -> some View {
        BrandView(isSignedIn: isSignedIn)
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    let suiteAttributeCount = result.output.components(separatedBy: "@Suite").count - 1
    #expect(suiteAttributeCount == 1)
    #expect(result.output.contains("@Suite(.sizes(.minimum))"))
    #expect(result.output.contains("@Test("))
    #expect(result.reasons.isEmpty)
  }
}
