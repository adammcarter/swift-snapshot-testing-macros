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
