import Foundation
import Testing

@testable import SnapshotMigrationSupport

/// Migrated sources are read and maintained by adopters forever, so the rewriter's output has to
/// look hand-written. Removing the return clause used to delete `-> some View` while leaving the
/// space that preceded it, stranding a double space against the body's brace.
@Suite
struct SnapshotMigrationRewriterSpacingTests {
  @Test(
    "Removing the return clause leaves exactly one space before the body brace",
    arguments: [
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Card")
        func card() -> some View {
          CardView()
        }
      }
      """,
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Card", configurations: cardConfigurations)
        func card(snapshot: CardSnapshot) -> some View {
          snapshot.makeView()
        }
      }
      """,
    ]
  )
  func migratedSignaturesKeepSingleSpacing(source: String) throws {
    let output = try SnapshotMigrationRewriter().rewrite(source: source).output

    #expect(!output.contains(")  {"), "migrated output has a double space before a body brace")
    #expect(output.contains(") {"))
  }
}

/// Removing a redundant attribute must take its whole line with it. Deleting only the attribute's
/// text left the newline behind, so every migrated suite gained a blank line where `@Suite` had
/// been folded into `@SnapshotSuite`.
@Suite
struct SnapshotMigrationRewriterAttributeLineTests {
  @Test("Folding a bare @Suite into the legacy attribute leaves no blank line")
  func removingARedundantAttributeRemovesItsLine() throws {
    let output = try SnapshotMigrationRewriter().rewrite(
      source: """
        import Testing

        @Suite
        @SnapshotSuite(.sizes(.minimum))
        @MainActor
        struct Snapshots {
          @SnapshotTest("Card")
          func card() -> some View {
            CardView()
          }
        }
        """
    ).output

    #expect(!output.contains("\n\n\n"), "migrated output gained a blank line:\n\(output)")
    #expect(output.contains("@Suite(.sizes(.minimum))\n@MainActor"))
  }
}
