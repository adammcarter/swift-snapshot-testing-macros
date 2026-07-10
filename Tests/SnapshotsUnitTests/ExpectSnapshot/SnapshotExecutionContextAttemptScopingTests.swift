import Testing

@testable import SnapshotTestingMacros

/// A minimal `SnapshotTestScoping` conformance that adds no behaviour of its own.
///
/// Invoking its `provideScope(for:testCase:performing:)` requirement mirrors exactly what the
/// Swift Testing runner does once per attempt of a test, which lets these tests simulate
/// attempts (retries / repetitions) without a real runner.
struct AttemptScopePassthroughTrait: SnapshotTestScoping {
  func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await function()
  }
}

struct SnapshotContextAttemptScopingTests {
  /// (R2) A new attempt of the same test — the runner invoking `provideScope` again — must get
  /// a fresh execution context: the first unnamed assertion resolves the *unsuffixed* base name
  /// again instead of drifting to "-2".
  @Test
  func secondAttemptResolvesTheUnsuffixedBaseNameAgain() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    var firstResolvedNames = [String]()

    for _ in 0 ..< 2 {
      try await trait.provideScope(for: test, testCase: Test.Case.current) {
        let name = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
          $0.resolvedAssertionName(named: nil)
        }
        firstResolvedNames.append(name)
      }
    }

    #expect(firstResolvedNames == ["profileCard", "profileCard"])
  }

  /// A suite-level trait invocation (`testCase == nil`) wraps ALL of a suite's tests in one
  /// `provideScope` call. It must NOT bind an attempt token, otherwise every test in the suite
  /// shares one execution context and artifact names leak across tests (observed: `singular()`
  /// resolving names under `helperWrappedUnnamedAssertionsReuseTheSameContext-2`).
  @Test
  func suiteLevelScopeDoesNotShareOneContextAcrossTestCaseScopes() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    let testCase = try #require(Test.Case.current)
    var firstResolvedNames = [String]()

    try await trait.provideScope(for: test, testCase: nil) {
      for _ in 0 ..< 2 {
        try await trait.provideScope(for: test, testCase: testCase) {
          let name = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
            $0.resolvedAssertionName(named: nil)
          }
          firstResolvedNames.append(name)
        }
      }
    }

    #expect(firstResolvedNames == ["profileCard", "profileCard"])
  }

  /// (R1) Sequential child tasks spawned by the test body share the attempt's context, so
  /// unnamed assertions suffix deterministically across the whole attempt.
  @Test
  func sequentialChildTasksShareTheAttemptContextAndSuffixDeterministically() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    var resolutions = [(contextID: ObjectIdentifier, name: String)]()

    try await trait.provideScope(for: test, testCase: Test.Case.current) {
      resolutions.append(
        TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
          (ObjectIdentifier($0), $0.resolvedAssertionName(named: nil))
        }
      )

      for _ in 0 ..< 2 {
        let resolution = await Task {
          TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
            (ObjectIdentifier($0), $0.resolvedAssertionName(named: nil))
          }
        }
        .value
        resolutions.append(resolution)
      }
    }

    #expect(resolutions.map(\.name) == ["profileCard", "profileCard-2", "profileCard-3"])
    #expect(Set(resolutions.map(\.contextID)).count == 1)
  }

  /// Macro-generated tests reach traits through `__TestScopingBox`, so the boxed path must
  /// establish the same attempt scope as direct conformances.
  @Test
  func boxedTraitScopeSharesTheAttemptContextWithChildTasks() async throws {
    let box = __TestScopingBox(AttemptScopePassthroughTrait())
    let test = try #require(Test.current)
    var resolutions = [(contextID: ObjectIdentifier, name: String)]()

    try await box.provideScope(for: test, testCase: Test.Case.current) {
      resolutions.append(
        TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
          (ObjectIdentifier($0), $0.resolvedAssertionName(named: nil))
        }
      )

      let resolution = await Task {
        TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
          (ObjectIdentifier($0), $0.resolvedAssertionName(named: nil))
        }
      }
      .value
      resolutions.append(resolution)
    }

    #expect(resolutions.map(\.name) == ["profileCard", "profileCard-2"])
    #expect(Set(resolutions.map(\.contextID)).count == 1)
  }

  /// Without an attempt scope each assertion deliberately gets a fresh context: any reuse
  /// keyed on task identity would let recycled task pointers resurrect a stale context (see
  /// `TaskLocalSnapshotExecutionContext.resolveContext`).
  @Test
  func withoutAScopeEachWithCurrentCallGetsAFreshContext() {
    let first = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
    let second = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }

    #expect(first !== second)
  }

  /// Without a trait-provided attempt token, assertion order has no safe lifetime owner.
  /// Distinct source call sites therefore provide the stable identity that prevents two unnamed
  /// assertions in one native test from resolving one reference.
  @Test
  func traitlessUnnamedAssertionsAtDistinctCallSitesResolveDistinctNames() {
    let first = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
      $0.resolvedAssertionName(named: nil)
    }
    let second = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") {
      $0.resolvedAssertionName(named: nil)
    }

    #expect(first != second)
  }

  /// The source identity is part of the on-disk reference contract. Line and column are reversible
  /// and collision-free within the source file whose path already owns the snapshot directory.
  @Test
  func callSiteIdentityUsesTheExactSourceLocation() {
    let name = TaskLocalSnapshotExecutionContext.withCurrent(
      function: "profileCard()",
      line: 10,
      column: 5
    ) {
      $0.resolvedAssertionName(named: nil)
    }

    #expect(name == "profileCard-L10C5")
  }

  /// (R3) Without any snapshot trait there is no attempt scope, and contexts must never be
  /// served from a cache keyed by recycled raw task pointers. A long run of short-lived
  /// sequential tasks at one source assertion must always resolve the same call-site-qualified
  /// name, regardless of task allocation reuse.
  @Test
  func sequentialTasksWithoutASnapshotTraitNeverResolveADriftedName() async {
    var names = [String]()

    for _ in 0 ..< 500 {
      let name = await Task {
        TaskLocalSnapshotExecutionContext.withCurrent(function: "probe()") {
          $0.resolvedAssertionName(named: nil)
        }
      }
      .value
      names.append(name)
    }

    #expect(Set(names).count == 1)
    #expect(names.first?.hasPrefix("probe-L") == true)
  }
}
