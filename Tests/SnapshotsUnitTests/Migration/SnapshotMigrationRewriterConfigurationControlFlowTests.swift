import Testing

@testable import SnapshotMigrationSupport

/// Covers `configurations:` `.map` closures whose configuration element expression is reachable
/// only through control flow (terminal if/switch expressions, returns nested in guard/if/switch).
/// The contract: such shapes are either fully rewritten to `SnapshotConfiguration<T>(...)`, or the
/// declaration is skipped with an explicit reason — never emitted as silent non-compiling output.
@Suite
struct MigrationConfigControlFlowTests {
  @Test
  func rewritesInitShorthandInsideTerminalIfExpressionOfMapClosure() throws {
    let input = """
    @SnapshotTest(
      configurations: Bool.allCases.map {
        if $0 {
          .init(name: "signed in", value: $0)
        } else {
          .init(name: "signed out", value: $0)
        }
      }
    )
    func makeView(isSignedIn: Bool) -> some View {
      BrandView(isSignedIn: isSignedIn)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(!result.output.contains(".init(name:"))
    #expect(result.output.contains("SnapshotConfiguration<Bool>(name: \"signed in\", value: $0)"))
    #expect(result.output.contains("SnapshotConfiguration<Bool>(name: \"signed out\", value: $0)"))
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func rewritesInitShorthandInReturnsNestedInSwitchOfMapClosure() throws {
    let input = """
    @SnapshotTest(
      configurations: Theme.allCases.map { theme in
        switch theme {
        case .light:
          return .init(name: "light", value: theme)
        default:
          return .init(name: "dark", value: theme)
        }
      }
    )
    func makeView(theme: Theme) -> some View {
      BrandView(theme: theme)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(!result.output.contains(".init(name:"))
    #expect(result.output.contains("return SnapshotConfiguration<Theme>(name: \"light\", value: theme)"))
    #expect(result.output.contains("return SnapshotConfiguration<Theme>(name: \"dark\", value: theme)"))
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  @Test
  func rewritesInitShorthandInGuardReturnOfMapClosure() throws {
    let input = """
    @SnapshotTest(
      configurations: states.map { state in
        guard state.isEnabled else {
          return .init(name: "disabled", value: state)
        }
        return .init(name: state.title, value: state)
      }
    )
    func profile(state: UserState) -> some View {
      UserProfileView(state: state)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(!result.output.contains(".init(name:"))
    #expect(result.output.contains("return SnapshotConfiguration<UserState>(name: \"disabled\", value: state)"))
    #expect(result.output.contains("return SnapshotConfiguration<UserState>(name: state.title, value: state)"))
    #expect(result.reasons.isEmpty)
    expectParsesCleanly(result.output)
  }

  /// An element-position bare `.init` shorthand the rewriter cannot type (unrecognized first label)
  /// must be surfaced as a skip, not emitted as ambiguous non-compiling output.
  @Test
  func skipsUnsupportedInitShorthandInControlFlowMapClosureWithReason() throws {
    let input = """
    @SnapshotTest(
      configurations: Bool.allCases.map {
        if $0 {
          .init(unexpected: $0)
        } else {
          .init(unexpected: $0)
        }
      }
    )
    func makeView(isSignedIn: Bool) -> some View {
      BrandView(isSignedIn: isSignedIn)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-configuration-shape" }))
    #expect(result.output.contains("@SnapshotTest"))
    expectParsesCleanly(result.output)
  }
}
