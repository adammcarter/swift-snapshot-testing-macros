import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterAttributeFormattingTests {
  @Test
  func removesWhitespaceOnlyLinesInsideMigratedAttributeBlock() throws {
    let input = "@MainActor" + "\n   \n" + """
    @SnapshotSuite(.theme(.light))
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite(.theme(.light))
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func normalizesSnapshotSuiteBeforeExistingSuite() throws {
    let input = """
    @MainActor
    @SnapshotSuite(.sizes(.minimum))

    @Suite("Cards")
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite("Cards", .sizes(.minimum))
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func collapsesMultipleDuplicateSuiteSeparators() throws {
    let input = """
    @MainActor
    @Suite
    """ + "\n  \t\n" + """
    @Suite
    @SnapshotSuite(.theme(.dark))
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite(.theme(.dark))
        struct CardSnapshots
        """
      )
    )
    #expect(result.output.components(separatedBy: "@Suite").count - 1 == 1)
    expectParsesCleanly(result.output)
  }

  @Test
  func splitsSameLineAttributesWhenBlockIsMigrated() throws {
    let input = """
    @MainActor @SnapshotSuite
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }
}
