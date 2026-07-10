import Foundation
import Testing

@testable import SnapshotTestingMacros

/// Per-case reference-name disambiguation for parameterized `@Test(arguments:)` tests.
///
/// The attempt-scoping fix gives every parameterized case a fresh ``SnapshotExecutionContext``,
/// so an unnamed, non-`argument:` `#expectSnapshot` would resolve the identical base name
/// (`<function>`) — and therefore the identical reference file — for every case, silently
/// overwriting on record and cross-comparing on verify. Folding the case's argument identity
/// into the resolved name gives each case a distinct reference file, while leaving
/// non-parameterized tests, named assertions, and `argument:`/configuration assertions exactly
/// as they were.
struct SnapshotCaseDiscriminatorNamingTests {
  // MARK: - Context-level folding

  /// A discriminated context (a parameterized case) folds its discriminator into the unnamed
  /// base name, so distinct cases resolve distinct reference names.
  @Test
  func discriminatedContextFoldsDiscriminatorIntoUnnamedName() {
    let alpha = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "alpha")
    let beta = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "beta")
    let gamma = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "gamma")

    let names = [
      alpha.resolvedAssertionName(named: nil),
      beta.resolvedAssertionName(named: nil),
      gamma.resolvedAssertionName(named: nil),
    ]

    #expect(names == ["profileCard-alpha", "profileCard-beta", "profileCard-gamma"])
    #expect(Set(names).count == 3)
  }

  /// A non-parameterized test has no discriminator, so its unnamed assertion keeps the exact
  /// base name recorded before this change. Guards existing references from churning.
  @Test
  func nonParameterizedContextKeepsTheBaseName() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-2")
  }

  /// Two unnamed assertions within one parameterized case share the case's context, so they
  /// suffix deterministically off the discriminated base name.
  @Test
  func twoUnnamedAssertionsInOneCaseSuffixOffTheDiscriminatedName() {
    let context = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "alpha")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard-alpha")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-alpha-2")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-alpha-3")
  }

  /// A named assertion is the user's deliberate choice and is never rewritten with the case
  /// discriminator, even inside a parameterized case.
  @Test
  func namedAssertionIsUnaffectedByTheDiscriminator() {
    let context = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "alpha")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-2")
  }

  /// The `argument:`/configuration path already distinguishes cases by the configuration name,
  /// so the adapter suppresses the case discriminator there (`disambiguatesUnnamedCase: false`)
  /// and the display name keeps its pre-change value.
  @Test
  func configurationPathSuppressesTheCaseDiscriminator() {
    let context = SnapshotExecutionContext(function: "profileCard()", caseDiscriminator: "alpha")

    #expect(context.resolvedAssertionName(named: nil, disambiguatesUnnamedCase: false) == "profileCard")
  }

  // MARK: - Discriminator extraction

  /// The extractor derives a normalized discriminator from a real parameterized `Test.Case`'s
  /// argument, mirroring how the `argument:` path derives its configuration name.
  @Test(arguments: ["alpha", "beta", "gamma"])
  func extractorDerivesDiscriminatorFromParameterizedCase(argument: String) throws {
    let testCase = try #require(Test.Case.current)

    #expect(SnapshotCaseDiscriminator.identity(for: testCase)?.discriminator == argument)
  }

  /// A non-parameterized case has no argument identity, so the extractor returns `nil` and the
  /// base name is preserved.
  @Test
  func extractorReturnsNilForNonParameterizedCase() throws {
    let testCase = try #require(Test.Case.current)

    #expect(SnapshotCaseDiscriminator.identity(for: testCase) == nil)
    #expect(SnapshotCaseDiscriminator.identity(for: nil) == nil)
  }

  // MARK: - End-to-end through the attempt scope

  /// End-to-end: driving `provideScope` with a real parameterized `Test.Case` (exactly what the
  /// Swift Testing runner does per case) must resolve a distinct, argument-folded reference name
  /// for each case's unnamed assertion.
  @Test(arguments: ["alpha", "beta", "gamma"])
  func parameterizedCaseResolvesArgumentFoldedNameThroughProvideScope(argument: String) async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    let testCase = try #require(Test.Case.current)

    var resolved: String?
    try await trait.provideScope(for: test, testCase: testCase) {
      resolved = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
        $0.resolvedAssertionName(named: nil)
      }
    }

    #expect(resolved == "profileCard-\(argument)")
  }

  // MARK: - Cross-case collision guard

  /// Two distinct case values that fold to one discriminator (`"v1.0"` and `"v1 0"` both
  /// normalize to `"v1-0"`) would resolve one reference file. The guard detects the clash and
  /// reports the previously-registered conflicting value description, so the caller can skip
  /// instead of silently overwriting the other case's reference.
  @Test
  func distinctCaseValuesFoldingToOneNameAreDetectedAsAConflict() {
    let callSite = "File.swift:10:5"

    let first = SnapshotExecutionContext(
      function: "hero()",
      caseIdentity: SnapshotCaseIdentity(discriminator: "v1-0", rawDescription: "v1.0")
    )
    let second = SnapshotExecutionContext(
      function: "hero()",
      caseIdentity: SnapshotCaseIdentity(discriminator: "v1-0", rawDescription: "v1 0")
    )

    let firstName = first.resolvedAssertionName(named: nil)
    let secondName = second.resolvedAssertionName(named: nil)
    #expect(firstName == secondName)

    // First case claims the name; no prior value, so no conflict.
    #expect(first.conflictingCaseDescription(forResolvedName: firstName, callSite: callSite) == nil)
    // Second, differently-described case resolves the same name — a conflict naming the first.
    #expect(
      second.conflictingCaseDescription(forResolvedName: secondName, callSite: callSite) == "v1.0"
    )
  }

  /// A repetition of the *same* case (same raw description) resolving the same name is not a
  /// conflict — repetitions and retries must re-resolve their own reference file.
  @Test
  func sameCaseValueResolvingTheSameNameIsNotAConflict() {
    let callSite = "File.swift:20:5"

    let attemptOne = SnapshotExecutionContext(
      function: "hero()",
      caseIdentity: SnapshotCaseIdentity(discriminator: "big", rawDescription: "big")
    )
    let attemptTwo = SnapshotExecutionContext(
      function: "hero()",
      caseIdentity: SnapshotCaseIdentity(discriminator: "big", rawDescription: "big")
    )

    let name = attemptOne.resolvedAssertionName(named: nil)
    #expect(attemptOne.conflictingCaseDescription(forResolvedName: name, callSite: callSite) == nil)
    #expect(attemptTwo.conflictingCaseDescription(forResolvedName: name, callSite: callSite) == nil)
  }

  /// A non-parameterized context has no case description, so the guard never reports a conflict.
  @Test
  func nonParameterizedContextNeverConflicts() {
    let context = SnapshotExecutionContext(function: "hero()")
    let name = context.resolvedAssertionName(named: nil)

    #expect(
      context.conflictingCaseDescription(forResolvedName: name, callSite: "File.swift:30:5") == nil
    )
  }
}
