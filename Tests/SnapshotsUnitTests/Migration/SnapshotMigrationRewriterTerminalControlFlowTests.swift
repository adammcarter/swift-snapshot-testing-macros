import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationRewriterControlFlowTests {
  @Test
  func skipsTerminalIfStatementWithBranchReturns() throws {
    let input = """
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard() -> some View {
        if useCompactLayout {
          return ProfileCard(style: .compact)
        } else {
          return ProfileCard(style: .regular)
        }
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-signature-shape" }))
    #expect(result.output.contains("@SnapshotTest"))
    #expect(!result.output.contains("let snapshotValue"))
    #expect(!result.output.contains("#expectSnapshot"))
  }

  @Test
  func skipsTerminalSwitchStatementWithCaseReturns() throws {
    let input = """
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard() -> some View {
        switch style {
        case .compact:
          return ProfileCard(style: .compact)
        default:
          return ProfileCard(style: .regular)
        }
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.contains(where: { $0.code == "unsupported-signature-shape" }))
    #expect(result.output.contains("@SnapshotTest"))
    #expect(!result.output.contains("let snapshotValue"))
    #expect(!result.output.contains("#expectSnapshot"))
  }

  @Test
  func rewritesTerminalIfExpressionWithoutReturns() throws {
    let input = """
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard() -> some View {
        if useCompactLayout {
          ProfileCard(style: .compact)
        } else {
          ProfileCard(style: .regular)
        }
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.output.contains("@Test"))
    #expect(result.output.contains("let snapshotValue = if useCompactLayout"))
    #expect(result.output.contains("#expectSnapshot(snapshotValue)"))
    #expect(!result.output.contains("return"))
  }

  @Test
  func rewritesTerminalExpressionContainingClosureWithInnerReturn() throws {
    let input = """
    @SnapshotSuite
    struct ProfileCardSnapshots {
      @SnapshotTest
      func profileCard() -> some View {
        VStack {
          Button(action: { return handleTap() }) {
            Text("Tap")
          }
        }
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.output.contains("@Test"))
    #expect(result.output.contains("let snapshotValue = VStack"))
    #expect(result.output.contains("{ return handleTap() }"))
    #expect(result.output.contains("#expectSnapshot(snapshotValue)"))
  }
}
