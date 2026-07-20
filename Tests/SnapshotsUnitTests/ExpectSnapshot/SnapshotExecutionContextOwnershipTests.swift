import Testing

@testable import SnapshotTestingMacros

struct SnapshotExecutionContextOwnershipTests {
  @Test
  func repeatedUnnamedAssertionsIncrementInsideOneContext() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-2")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-3")
  }

  @Test
  func repeatedNamedAssertionsSuffixOnlyOnCollision() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-2")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-3")
  }

  @Test
  func generatedAndExplicitNamesDoNotCollide() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-2")
    #expect(context.resolvedAssertionName(named: "profileCard-2") == "profileCard-2-2")
  }

  @Test
  func detachedTaskDoesNotInheritTaskLocalContext() async {
    let inherited = await TaskLocalSnapshotExecutionContext.$current.withValue(
      SnapshotExecutionContext(function: "profileCard()")
    ) {
      await Task.detached {
        TaskLocalSnapshotExecutionContext.current != nil
      }
      .value
    }

    #expect(inherited == false)
  }

  // Behaviour change (attempt-token design): repeated `withCurrent` calls used to reuse a
  // context cached under raw current-task pointer bits, which the allocator recycles for new
  // tasks almost immediately — retries and repetitions then inherited a STALE context and
  // artifact names silently drifted. Cross-call reuse is now provided by the attempt token
  // that every snapshot trait's scope binds around the test body; without that scope each
  // call deliberately gets a fresh context.
  @Test
  func repeatedWithCurrentCallsReuseTheContextOfTheEnclosingAttempt() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    var first: SnapshotExecutionContext?
    var second: SnapshotExecutionContext?

    try await trait.provideScope(for: test, testCase: Test.Case.current) {
      first = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
      second = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
    }

    #expect(first != nil)
    #expect(first === second)
  }

  // Behaviour change (attempt-token design): this test previously asserted that a child task
  // gets a FRESH cached context. That behaviour fell out of caching contexts under raw
  // current-task pointer bits, which the allocator recycles — new tasks (retries, repetitions,
  // sequential child tasks) frequently inherited a STALE context and unnamed artifact names
  // silently drifted to "-2"/"-3" suffixes. Under the attempt token bound by every snapshot
  // trait's scope, all work inside ONE attempt — including child tasks, which inherit the
  // task-local token — SHARES the attempt's context, keeping suffixes stable and deterministic.
  @Test
  func childTaskSharesTheContextOfTheEnclosingAttempt() async throws {
    let trait = AttemptScopePassthroughTrait()
    let test = try #require(Test.current)
    var parent: SnapshotExecutionContext?
    var child: SnapshotExecutionContext?

    try await trait.provideScope(for: test, testCase: Test.Case.current) {
      parent = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
      child = await Task {
        TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
      }
      .value
    }

    #expect(parent != nil)
    #expect(parent === child)
  }
}
