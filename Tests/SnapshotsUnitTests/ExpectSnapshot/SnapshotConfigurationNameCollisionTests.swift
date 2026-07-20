import Testing

@testable import SnapshotTestingMacros

/// Distinct configuration values whose derived names normalize identically — e.g. "v1.0" and
/// "v1 0" both fold to "v1-0" — must be surfaced as an Issue instead of silently pointing two
/// test cases at the same reference file.
struct SnapshotConfigurationNameCollisionTests {

  // MARK: - Registry semantics

  @Test
  func firstRegistrationForACallSiteHasNoConflict() {
    let registry = SnapshotConfigurationNameCollisions()

    let conflict = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )

    #expect(conflict == nil)
  }

  @Test
  func reRegisteringTheSameValueDescriptionHasNoConflict() {
    let registry = SnapshotConfigurationNameCollisions()

    _ = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )
    let conflict = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )

    #expect(conflict == nil)
  }

  @Test
  func distinctValueDescriptionsForTheSameDerivedNameConflict() {
    let registry = SnapshotConfigurationNameCollisions()

    _ = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )
    let conflict = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1 0"
    )

    #expect(conflict == "v1.0")
  }

  @Test
  func distinctCallSitesDoNotConflict() {
    let registry = SnapshotConfigurationNameCollisions()

    _ = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )
    let conflict = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:20:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1 0"
    )

    #expect(conflict == nil)
  }

  @Test
  func distinctOccurrencesWithinOneAttemptDoNotConflict() {
    let registry = SnapshotConfigurationNameCollisions()

    _ = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 1,
      valueDescription: "v1.0"
    )
    let conflict = registry.conflictingValueDescription(
      callSite: "/tmp/A.swift:10:5",
      derivedName: "v1-0",
      occurrence: 2,
      valueDescription: "v1 0"
    )

    #expect(conflict == nil)
  }

  // MARK: - Per-attempt occurrence indices

  @Test
  func occurrenceIndicesCountPerKeyWithinOneContext() {
    let context = SnapshotExecutionContext(function: "myView()")

    #expect(context.nextOccurrenceIndex(forKey: "a") == 1)
    #expect(context.nextOccurrenceIndex(forKey: "a") == 2)
    #expect(context.nextOccurrenceIndex(forKey: "b") == 1)
  }

  // MARK: - Adapter integration

  @Test
  func collidingDerivedNamesAcrossAttemptsRecordAnIssueAndSkipTheAssertion() {
    // Two cases of one parameterized test: same call site, fresh context per attempt.
    let first = ExpectSnapshotAdapter.resolvedConfiguration(
      from: SnapshotConfiguration(name: nil, value: "v1.0"),
      context: SnapshotExecutionContext(function: "myView()"),
      fileID: "SnapshotsUnitTests/CollisionA.swift",
      filePath: "/tmp/CollisionA.swift",
      line: 10,
      column: 5
    )

    #expect(first?.name == "v1-0")

    withKnownIssue {
      let second = ExpectSnapshotAdapter.resolvedConfiguration(
        from: SnapshotConfiguration(name: nil, value: "v1 0"),
        context: SnapshotExecutionContext(function: "myView()"),
        fileID: "SnapshotsUnitTests/CollisionA.swift",
        filePath: "/tmp/CollisionA.swift",
        line: 10,
        column: 5
      )

      #expect(second == nil)
    }
  }

  @Test
  func collidingDerivedNamesWithinOneAttemptAreNotACollision() {
    // A loop over one call site within a single attempt: display-name dedupe already
    // disambiguates the artifacts, so no issue may be recorded.
    let context = SnapshotExecutionContext(function: "myView()")

    let first = ExpectSnapshotAdapter.resolvedConfiguration(
      from: SnapshotConfiguration(name: nil, value: "v1.0"),
      context: context,
      fileID: "SnapshotsUnitTests/CollisionB.swift",
      filePath: "/tmp/CollisionB.swift",
      line: 10,
      column: 5
    )
    let second = ExpectSnapshotAdapter.resolvedConfiguration(
      from: SnapshotConfiguration(name: nil, value: "v1 0"),
      context: context,
      fileID: "SnapshotsUnitTests/CollisionB.swift",
      filePath: "/tmp/CollisionB.swift",
      line: 10,
      column: 5
    )

    #expect(first?.name == "v1-0")
    #expect(second?.name == "v1-0")
  }

  @Test
  func repeatingTheSameCaseValueAcrossAttemptsIsNotACollision() {
    // Xcode repetitions and retries re-run the same case with the same value.
    for _ in 1 ... 3 {
      let resolved = ExpectSnapshotAdapter.resolvedConfiguration(
        from: SnapshotConfiguration(name: nil, value: "v1.0"),
        context: SnapshotExecutionContext(function: "myView()"),
        fileID: "SnapshotsUnitTests/CollisionC.swift",
        filePath: "/tmp/CollisionC.swift",
        line: 10,
        column: 5
      )

      #expect(resolved?.name == "v1-0")
    }
  }

  @Test
  func explicitlyNamedConfigurationsAreNeverTreatedAsCollisions() {
    // Explicit names are the user's deliberate choice; value descriptions may legitimately
    // vary between enumerations (object addresses, dates), so only derived names are guarded.
    let first = ExpectSnapshotAdapter.resolvedConfiguration(
      from: SnapshotConfiguration(name: "same", value: "v1.0"),
      context: SnapshotExecutionContext(function: "myView()"),
      fileID: "SnapshotsUnitTests/CollisionD.swift",
      filePath: "/tmp/CollisionD.swift",
      line: 10,
      column: 5
    )
    let second = ExpectSnapshotAdapter.resolvedConfiguration(
      from: SnapshotConfiguration(name: "same", value: "v1 0"),
      context: SnapshotExecutionContext(function: "myView()"),
      fileID: "SnapshotsUnitTests/CollisionD.swift",
      filePath: "/tmp/CollisionD.swift",
      line: 10,
      column: 5
    )

    #expect(first?.name == "same")
    #expect(second?.name == "same")
  }
}
