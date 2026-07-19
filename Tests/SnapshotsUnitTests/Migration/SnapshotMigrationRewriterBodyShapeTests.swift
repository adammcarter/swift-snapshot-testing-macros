import Foundation
import Testing

@testable import SnapshotMigrationSupport

/**
 Migrated bodies are read and maintained by adopters forever, so a one-line legacy test must not
 become four lines of ceremony.

 The hoisting is safe to drop because the rewriter always makes the migrated declaration
 `@MainActor`: evaluating the value eagerly at the statement and lazily inside the snapshot
 operation therefore happen on the same actor, so the locals bought isolation that was already
 guaranteed. They are kept only where evaluation order is genuinely observable — a body with
 prelude statements, or one that binds more than a single value.
 */
@Suite
struct SnapshotMigrationRewriterBodyShapeTests {
  private func migrate(_ source: String) throws -> String {
    try SnapshotMigrationRewriter().rewrite(source: source).output
  }

  @Test("A single-expression configured body migrates to one assertion line")
  func singleExpressionConfiguredBodyIsEmittedTightly() throws {
    let output = try migrate(
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Entities", configurations: entityConfigurations)
        func entity(snapshot: EntitySnapshot) -> some View {
          snapshot.makeView()
        }
      }
      """
    )

    #expect(output.contains(#"#expectSnapshot(configuration, named: "Entities") {"#))
    #expect(output.contains("$0.makeView()"))
    #expect(!output.contains("let snapshotConfiguration = configuration"))
    #expect(!output.contains("let snapshotValue ="))
  }

  /// The alias was only ever defensive against a later statement shadowing `configuration`, so it
  /// must not survive where nothing can shadow it.
  @Test("The configuration is never aliased for its own sake")
  func configurationIsNotAliased() throws {
    let output = try migrate(
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Card", configurations: cardConfigurations)
        func card(snapshot: CardSnapshot) -> some View {
          snapshot.makeView()
        }
      }
      """
    )

    #expect(!output.contains("snapshotConfiguration"))
  }

  @Test("A parameter used more than once keeps its name rather than repeating $0")
  func repeatedParameterKeepsANamedBinding() throws {
    let output = try migrate(
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Pair", configurations: pairConfigurations)
        func pair(snapshot: PairSnapshot) -> some View {
          PairView(before: snapshot.before, after: snapshot.after)
        }
      }
      """
    )

    #expect(output.contains("{ snapshot in"))
    #expect(!output.contains("$0"))
  }

  /// A body whose value depends on earlier statements keeps them, and keeps evaluating them in
  /// their original order, because that order is observable.
  @Test("A body with prelude statements keeps its hoisted form")
  func multiStatementBodyKeepsItsStatements() throws {
    let output = try migrate(
      """
      @Suite
      @SnapshotSuite
      struct Snapshots {
        @SnapshotTest("Card", configurations: cardConfigurations)
        func card(snapshot: CardSnapshot) -> some View {
          let theme = Theme.resolve(for: snapshot)
          return CardView(snapshot: snapshot, theme: theme)
        }
      }
      """
    )

    #expect(output.contains("let theme = Theme.resolve(for: snapshot)"))
    #expect(output.contains("#expectSnapshot("))
  }
}

/// `configurationValues:` must read like `configurations:` does. Its `snapshotConfiguration` is
/// genuine construction rather than an alias and stays, but hoisting the value into a local only
/// to return it from a closure that ignores its argument is the same ceremony, and goes.
@Suite
struct SnapshotMigrationRewriterValuesShapeTests {
  @Test("A single-expression configurationValues body migrates to one assertion")
  func singleExpressionValuesBodyIsEmittedTightly() throws {
    let output = try SnapshotMigrationRewriter().rewrite(
      source: """
        @SnapshotTest(configurationValues: makeUserStates())
        func userProfile(state: UserState) -> some View {
          UserProfileView(state: state)
        }
        """
    ).output

    #expect(output.contains(#"let snapshotConfiguration = SnapshotConfiguration(name: "\(state)", value: state)"#))
    #expect(output.contains(#"#expectSnapshot(snapshotConfiguration, named: "userProfile") {"#))
    #expect(output.contains("UserProfileView(state: $0)"))
    #expect(!output.contains("let snapshotValue"))
  }
}
