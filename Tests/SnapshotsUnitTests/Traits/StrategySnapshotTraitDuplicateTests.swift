import Testing

@testable import SnapshotTestingMacros

/// A trait that is not a `.strategy`, to prove the count is not simply "how many traits".
private struct UnrelatedTrait: SnapshotSuiteTrait, SnapshotTestTrait {}

/// `prepare(for:)` receives a declaration's inherited traits merged with its own, in that order,
/// and nothing distinguishes the two halves — so the check is driven by where each `.strategy`
/// was written relative to the declaration's own attribute. These cases pin both halves of that:
/// a duplicate on one declaration is rejected, and the documented suite-default/test-override
/// hierarchy is not.
///
/// The suite carries a `.strategy` so the two end-to-end cases below run against a real
/// suite-default/test-override hierarchy rather than a hand-built trait array.
@Suite(.strategy(.image))
struct StrategySnapshotTraitDuplicateTests {
  /// The `@Test` / `@Suite` attribute of the declaration under test, for these fixtures.
  private static let declaration = SourceLocation(
    fileID: "SnapshotsUnitTests/Fixture.swift",
    filePath: "/fixtures/Fixture.swift",
    line: 20,
    column: 4
  )

  @Test(
    arguments: [
      [] as [any Testing.Trait],
      [UnrelatedTrait()],
      [strategy(.image, line: 20)],
      [strategy(.recursiveDescription, line: 21), UnrelatedTrait()],
      // A suite default (declared above the test's attribute) plus the test's own override.
      [strategy(.image, line: 9), strategy(.recursiveDescription, line: 20)],
      // Two enclosing suites plus this declaration: still one strategy per declaration.
      [
        strategy(.image, line: 4),
        strategy(.image, line: 9),
        strategy(.recursiveDescription, line: 20),
      ],
      // Declared in another file entirely — not this declaration's to reject.
      [
        strategy(.image, line: 20, fileID: "OtherModule/Shared.swift"),
        strategy(.recursiveDescription, line: 20),
      ],
      // The legacy macro expansion applies scoping traits through `__TestScopingBox`, so a
      // single boxed strategy must not read as a conflict either.
      [__TestScopingBox(strategy(.image, line: 20))],
    ]
  )
  func acceptsAtMostOneStrategyTraitPerDeclaration(traits: [any Testing.Trait]) throws {
    try StrategySnapshotTrait.validateSingleApplication(in: traits, declaredAt: Self.declaration)
  }

  @Test
  func rejectsTwoDistinctStrategyTraitsNamingBoth() {
    let error = capturedConflict(
      in: [strategy(.image, line: 20), strategy(.recursiveDescription, line: 20)]
    )

    #expect(error?.description.contains("image, recursiveDescription") == true)
    #expect(error?.description.contains("Only one snapshot strategy may apply") == true)
  }

  /// A multi-line attribute puts the second trait on a later line than the declaration's own
  /// source location, so "same line" would be the wrong rule.
  @Test
  func rejectsDuplicatesSpreadOverAMultiLineAttribute() {
    let error = capturedConflict(
      in: [strategy(.image, line: 21), strategy(.recursiveDescription, line: 22)]
    )

    #expect(error?.description.contains("image, recursiveDescription") == true)
  }

  /// Two identical strategies are still a conflict: the rule is one trait, not one value, and
  /// silently collapsing them would make "does the second one do anything?" answer differently
  /// for identical and differing values.
  @Test
  func rejectsTwoIdenticalStrategyTraits() {
    let error = capturedConflict(
      in: [strategy(.image, line: 20), strategy(.image, line: 21)]
    )

    #expect(error?.description.contains("image, image") == true)
  }

  @Test
  func namesEveryConflictingStrategyInDeclarationOrder() {
    let error = capturedConflict(
      in: [
        strategy(.recursiveDescription, line: 20),
        UnrelatedTrait(),
        strategy(.image, line: 21),
        strategy(.recursiveDescription, line: 22),
      ]
    )

    #expect(
      error?.description.contains("recursiveDescription, image, recursiveDescription") == true
    )
  }

  /// The legacy `@SnapshotSuite` / `@SnapshotTest` expansion applies scoping traits wrapped in
  /// `__TestScopingBox`, so the check has to see through the box or it would only ever fire on
  /// the native `@Test` / `@Suite` surface.
  @Test
  func rejectsDuplicatesAppliedThroughTheLegacyScopingBox() {
    let error = capturedConflict(
      in: [
        __TestScopingBox(strategy(.image, line: 20)),
        strategy(.recursiveDescription, line: 21),
      ]
    )

    #expect(error?.description.contains("image, recursiveDescription") == true)
  }

  /// Exercises `prepare(for:)` against a real `Test` whose declaration carries a `.strategy`
  /// and whose enclosing suite carries a different one — the shape the package documents as
  /// "suite traits for defaults and test traits for local overrides".
  ///
  /// Swift Testing merges the suite's recursive traits into this test's `traits` before
  /// `prepare(for:)` sees them, so a check that only counted would reject this.
  @Test(.strategy(.recursiveDescription))
  func suiteDefaultOverriddenByThisTestIsNotAConflict() async throws {
    let test = try #require(Test.current)
    try #require(test.traits.compactMap { $0 as? StrategySnapshotTrait }.count == 2)

    try await StrategySnapshotTrait(strategy: .image).prepare(for: test)
  }

  /// The other half, end to end: a second `.strategy` written on *this* declaration is rejected
  /// by the same `prepare(for:)` call, with this file's real source locations.
  @Test(.strategy(.image))
  func secondStrategyOnThisDeclarationIsRejected() async throws {
    var test = try #require(Test.current)
    test.traits.append(.strategy(.recursiveDescription))

    await #expect(throws: ConflictingStrategySnapshotTraits.self) {
      try await StrategySnapshotTrait(strategy: .image).prepare(for: test)
    }
  }

  private static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy,
    line: Int,
    fileID: String = "SnapshotsUnitTests/Fixture.swift"
  ) -> StrategySnapshotTrait {
    StrategySnapshotTrait(
      strategy: strategy,
      sourceLocation: SourceLocation(
        fileID: fileID,
        filePath: "/fixtures/Fixture.swift",
        line: line,
        column: 4
      )
    )
  }

  private func strategy(
    _ strategy: StrategySnapshotTrait.Strategy,
    line: Int,
    fileID: String = "SnapshotsUnitTests/Fixture.swift"
  ) -> StrategySnapshotTrait {
    Self.strategy(strategy, line: line, fileID: fileID)
  }

  private func capturedConflict(
    in traits: [any Testing.Trait]
  ) -> ConflictingStrategySnapshotTraits? {
    do {
      try StrategySnapshotTrait.validateSingleApplication(in: traits, declaredAt: Self.declaration)
      Issue.record("Expected conflicting .strategy traits to be rejected")

      return nil
    }
    catch let error as ConflictingStrategySnapshotTraits {
      return error
    }
    catch {
      Issue.record("Expected ConflictingStrategySnapshotTraits, got: \(error)")

      return nil
    }
  }
}
