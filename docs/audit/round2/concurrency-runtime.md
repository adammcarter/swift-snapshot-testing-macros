# Audit round 2: concurrency-runtime

Verdict: the concurrency-runtime lane is in good shape. All 8 round-1 findings for this
lane were independently re-verified as genuinely fixed by direct code reading (not just
commit messages), across ExpectSnapshotAdapter.swift, Asserter.swift, SnapshotFailure.swift,
SnapshotAttemptToken.swift, TaskLocalSnapshotExecutionContext.swift,
SnapshotExecutionContext.swift, SnapshotRuntimePreconditions.swift, and the trait-scoping
types. Three hotspots were signed off explicitly: (1) the sync bridge
(ExpectSnapshotAdapter.swift:1013-1056) never records Issue.record/XCTFail inside the
DispatchQueue.main.sync/assumeIsolated hop — failures are collected as values and recorded
on the caller's task after the hop returns, exercised by SnapshotIssueAttributionTests
against the real off-main bridge; (2) SnapshotAttemptToken.withAttemptScope's early-return
(line 47) is correct — each test-case attempt gets a fresh withValue scope, the
testCase!=nil guard prevents suite-level token binding, and no trait bypasses the 3-arg
provideScope, with the old task-pointer cache fully deleted; (3) the trait-less bare @Test
fallback (TaskLocalSnapshotExecutionContext.swift:44-57) produces a deterministic (not
racy) same-name collision for multiple unnamed assertions in one trait-less test, which is
documented (Usage.md:59-61) and judged an acceptable, documented trade-off rather than a
bug. No new sharp race, leak, deadlock, or attribution defect was found. Four residual
low/improvement items remain, listed below by severity.

## Findings

### 1. Concurrent sibling-task unnamed assertions get order-dependent suffixes and reference files; Usage.md overclaims child-task determinism
- Severity: low
- File: Sources/SnapshotTestingMacros/Assertion/ExpectSnapshotAdapter.swift:1109
- Failure scenario: Two assertions execute in concurrent sibling child tasks (async let /
  task group) with unnamed (or same-named) snapshots. The order in which their two
  main-actor continuations run is nondeterministic, so which view becomes
  `profileCard.1.png` vs `profileCard-2.1.png` is nondeterministic. A record run and a
  later verify run can assign the two views to swapped reference files, producing
  spurious mismatches (reference flapping).
- Evidence: ExpectSnapshotAdapter.swift:1097-1109 resolves the name on the main actor
  inside `runMainActorSnapshot`; SnapshotExecutionContext.swift:20-37
  (`resolvedAssertionName` mutates the shared `usedNames` set under `nameState.lock` — the
  first caller to acquire the lock gets the base name, the next gets `-2`, so the result
  is sensitive to lock-acquisition/continuation order); SnapshotContextAttemptScopingTests.swift:68-93
  only exercises SEQUENTIAL child tasks (`await Task{...}.value`, one at a time) and
  asserts the deterministic `["profileCard","profileCard-2","profileCard-3"]`;
  Documentation/Usage.md:45-56 claims child-task coverage and per-assertion-order
  determinism without qualifying it to sequential execution.
- Suggested fix: Narrow the Usage.md claim to sequential child tasks and steer concurrent
  snapshot assertions to explicit distinct `named:` arguments; optionally add a
  concurrent-sibling test that pins the actual (order-independent-file,
  order-dependent-mapping) behavior, or resolve display names in source order before
  spawning children.
- needs_dynamic_verification: true

### 2. Reference-identifier scoping makes cross-test same-name collisions deterministic but does not eliminate them (testName carries no test identity)
- Severity: low
- File: Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/NameAssertionRequestGenerator.swift:54
- Failure scenario: `testName` is composed purely from `[configurationName, display name,
  size, theme]` and carries no enclosing-test-function identity, while
  `snapshotDirectory` is per-file. This is unsafe when (a) an explicit `named:` discards
  the `#function` baseName and bypasses the collision guard entirely (the guard returns
  early for explicit names), or (b) a shared helper's unnamed assertion uses the helper's
  `#function` for every caller. Two different tests in one file —
  `test1 #expectSnapshot(viewA, named: "foo")` and `test2 #expectSnapshot(viewB, named:
  "foo")`, or both calling a shared unnamed helper — resolve identical
  testName+directory and both land on `__Snapshots__/<File>/foo.1.png`, cross-wiring
  references (record: last-writer-wins; verify: the differing view fails persistently).
  Each context independently returns identifier `1` for its own key, so the per-attempt
  counter cannot separate them.
- Evidence: NameAssertionRequestGenerator.swift:54-63 (testName omits test-function
  identity); SnapshotExecutionContext.swift:52-54 (explicit override discards the
  `#function` baseName); ExpectSnapshotAdapter.swift:758-760 (`if configuration.name !=
  nil { return configuration }` — explicit names never reach
  SnapshotConfigurationNameCollisions); Asserter.swift:106-118, 155-164 (verifySnapshot
  called with the wrapper's own testName and a per-context identifier of `1`).
- Note: this is shared behavior with upstream pointfree and the round-2 fix is a genuine
  improvement (deterministic instead of order-dependent .1/.2 flakiness), not a
  regression — but it is a latent prod-readiness footgun and nuances the "fixes
  cross-test collisions" characterization; likely belongs to the naming/dedup lane.
- Suggested fix: Include a test-scope discriminator (e.g. enclosing test id / `#function`)
  in the reference path or testName, or extend the collision guard to explicit names and
  shared-helper baseNames, or document that explicit `named:` values and helper-hosted
  unnamed assertions must be unique within a file.
- needs_dynamic_verification: false

### 3. Coverage gap: no concurrent-sibling determinism test and no runner-driven token-binding test for a non-parameterized traited @Test
- Severity: improvement
- File: Tests/SnapshotsUnitTests/ExpectSnapshot/SnapshotExecutionContextAttemptScopingTests.swift:68
- Failure scenario: the attempt-scoping unit tests simulate the runner by calling
  `provideScope(for:testCase:)` manually with `Test.Case.current`, and only exercise
  sequential child tasks. Gaps: (1) no test covers concurrent sibling child tasks (see
  Finding 1), so the nondeterministic-mapping behavior is neither pinned nor prevented;
  (2) no test drives the real Swift Testing runner to confirm a non-parameterized @Test
  with a directly-applied snapshot trait actually receives a non-nil `testCase` — the
  load-bearing precondition for token binding. If the runner ever passed `testCase==nil`
  for a non-parameterized test, every traited single-case test would silently drop to the
  trait-less fallback. Currently only validated indirectly via CI-recorded integration
  references.
- Evidence: SnapshotExecutionContextAttemptScopingTests.swift:28-89 all invoke
  `trait.provideScope(...)` directly with `Test.Case.current` and use `await
  Task{}.value` sequentially; SnapshotTestScoping.swift:30 guards on `testCase != nil`.
- Suggested fix: Add a real `@Test(.theme(...))` (non-parameterized) that makes two
  unnamed `#expectSnapshot` calls and asserts distinct deterministic references
  (exercising the true runner path), plus a concurrent-sibling test documenting actual
  behavior under `async let` / task groups.
- needs_dynamic_verification: false

### 4. SnapshotConfigurationNameCollisions.shared is a process-global insert-only registry
- Severity: improvement
- File: Sources/SnapshotTestingMacros/Assertion/SnapshotConfigurationNameCollisions.swift:24
- Failure scenario: the old task-pointer context cache (round-1 findings 3/5) is fully
  removed, but the collision detector is a new process-lifetime singleton whose
  `valueDescriptionsByKey` dictionary is insert-only with no eviction. In practice this is
  bounded by the static test structure (distinct callSite x derivedName pairs = distinct
  references) and NOT grown by repetitions/retries (re-registering the same description
  is a no-op). The one residual: the key includes a per-attempt occurrence index, so a
  single attempt that hits one call site many times with the same derived name (e.g. a
  large loop of unnamed/same-value assertions) inserts one entry per iteration that
  persists for the process lifetime — a contrived pattern, minor note rather than a real
  leak.
- Evidence: SnapshotConfigurationNameCollisions.swift:24-25 (`static let shared`), 39-48
  (key = callSite|occurrence|derivedName; insert on first sight, never removed; repeated
  same-description is a no-op); ExpectSnapshotAdapter.swift:765 feeds `occurrence =
  context.nextOccurrenceIndex(...)` which counts per call-site within an attempt.
- Suggested fix: Leave as-is (acceptable), or optionally clear the registry per test-run
  via a scope hook, or cap/evict entries keyed by occurrence to remove the pathological
  same-name-loop growth.
- needs_dynamic_verification: false
