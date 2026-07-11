import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterAttributeFormattingTests {
  @Test
  func removesWhitespaceOnlyLinesInsideMigratedAttributeBlock() throws {
    let input = """
    @MainActor
       
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
}
