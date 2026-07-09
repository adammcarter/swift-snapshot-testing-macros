# Audit findings: traits-scoping

Traits-scoping review (max reasoning). Core architecture verified sound: suite/test/nested trait precedence rides swift-testing 6.1's scopeProvider defaults, task-locals propagate correctly through structured concurrency, the decorator read-modify-write merge is additive as intended, ResolvedSnapshotRuntimeState correctly carries all six trait task-locals across the DispatchQueue.main.sync hop, Bug/Condition/Tag/TimeLimit passthrough is pure inherited behavior, and all trait payloads are Sendable-sound. Six findings survived refutation, concentrated at the pointfree bridge boundary, plus one coverage-gap finding.

## 1. [HIGH] Native #expectSnapshot never scopes pointfree's snapshot counter — in-process repetitions and unnamed parameterized cases produce drifting '.N' reference names

- **File**: Sources/SnapshotTestingMacros/Assertion/Asserter.swift:149
- **Failure scenario**: Run a native `@Test` containing `#expectSnapshot` repeatedly in one process (Xcode "Run Repeatedly"/test iterations): iteration 2's counter.next() returns 2, so it looks for `name_min-size_light.2.png`, finds nothing, records a stray new reference and fails. Also: a parameterized native test (`@Test(arguments:)`) calling unnamed `#expectSnapshot` shares one counter key across concurrently-run cases, so identifier assignment is race-ordered — reference/actual pairing shuffles between runs.
- **Evidence**: `Asserter.swift:149` passes `named: nil` → pointfree's `AssertSnapshot.swift:324-331` derives the identifier from `counter.next(...)` → `AssertSnapshot.swift:555-567` selects `File.counter` (shared, growing-only) or `_counter` (XCTest-only reset). The only Swift Testing reset is `SnapshotsTestTrait.swift:54`, applied automatically only by the deprecated `@SnapshotSuite` macro (`SnapshotSuite.swift:113-117`). No other `File.counter`/`.snapshots` binding exists anywhere in Sources (grep-confirmed). Off-main tests lose `Test.current` across `DispatchQueue.main.sync` (`ExpectSnapshotAdapter.swift:798-813`), falling back to the never-reset `_counter` global.
- **Suggested fix**: Pass a deterministic `named:` value (e.g. `"1"`) instead of `nil` in `PointfreeAsserter.verifySnapshot` — matches existing `.1.png` references while removing dependence on pointfree's process-global counters. Separately fold `Test.Case` identity into the derived testName for parameterized tests.
- **needs_dynamic_verification**: false

## 2. [HIGH] Asserter's always-on withSnapshotTesting with non-optional trait defaults clobbers every pointfree-native config source

- **File**: Sources/SnapshotTestingMacros/Assertion/Asserter.swift:10
- **Failure scenario**: `SNAPSHOT_TESTING_RECORD=all swift test` (the standard pointfree re-record workflow) silently re-records nothing. `@Suite(.pointfreeSnapshots)` or pointfree's own `.snapshots(record: .all, diffTool: .ksdiff)` on a native suite/test has its config immediately overridden. User-level `withSnapshotTesting(record: .all) { #expectSnapshot(...) }` is also lost. This is a regression vs `main`, which had no such wrapper.
- **Evidence**: `Asserter.swift:8-18` wraps with non-nil `record`/`diffTool`; defaults at `RecordSnapshotTrait.swift:9-10` (`.missing`) and `DiffToolSnapshotTrait.swift:9-10` (`.default`). Pointfree resolution (`SnapshotTestingConfiguration.swift:26-40`, `AssertSnapshot.swift:304,523`) means a non-nil arg always wins, so env var / `.snapshots` trait / `isRecording` paths (`AssertSnapshot.swift:83-90,30-46,64-80`) become unreachable. Confirmed via `git show main:Sources/SnapshotTestingMacros/Assertion/Asserter.swift` that `main`'s Asserter had no wrapper at all.
- **Interaction**: makes the `.pointfreeSnapshots`-first suite-trait-ordering question moot today (config is clobbered regardless of position) — but becomes load-bearing once this is fixed.
- **Suggested fix**: Make `RecordSnapshotTrait.current`/`DiffToolSnapshotTrait.current` Optional with nil defaults and pass through unchanged so pointfree's own fallback chain (env var, `.snapshots` trait, `isRecording`) is restored when the package traits are absent. Also capture and re-bind `SnapshotTestingConfiguration.current` inside `withAppliedValues` so it survives the `DispatchQueue.main.sync` hop.
- **needs_dynamic_verification**: false

## 3. [HIGH, macOS, needs dynamic verify] .backgroundColor trait silently does nothing on macOS

- **File**: Sources/SnapshotTestingMacros/_Convenience/AppKit+Convenience.swift:17
- **Failure scenario**: `@Test(.backgroundColor(nsColor: .red))` on macOS renders with no background — the reference gets recorded without it, so the test passes, masking the loss until compared against iOS output of the same view.
- **Evidence**: the decorator writes via `layer?.backgroundColor = newValue?.cgColor` (`AppKit+Convenience.swift:14-19`) on the container view from `wrappingInContainerViewController`, which is never layer-backed (`rg -n wantsLayer Sources` returns nothing; `SnapshotView+wrappingInContainerView.swift:11`, `SnapshotViewGenerating+makeDecoratedView.swift:12-20`). At write time `layer` is nil so the optional chain silently discards the color. No macOS decorator reference images exist anywhere in the repo to catch this.
- **Interaction**: combines with known bug (2) — NSAppearance never applied — meaning macOS trait-driven rendering fidelity (theme + background) is entirely unverified.
- **Suggested fix**: Force layer-backing (`view.wantsLayer = true`) before assignment, or implement the fill via an explicit draw path independent of layer-backing. Add a macOS integration reference for `.backgroundColor`/`.padding`.
- **needs_dynamic_verification**: true

## 4. [MEDIUM] .record(false) maps to .never, diverging from pointfree's record:false == .missing bool semantics

- **File**: Sources/SnapshotTestingMacros/Traits/PointfreeSnapshotTesting/RecordSnapshotTrait+Init.swift:22
- **Failure scenario**: migrating `assertSnapshot(..., record: false)` to `@Test(.record(false))` changes semantics from "verify, auto-record missing references" to "never write, hard-fail on missing." On a fresh checkout or a new test under suite-level `.record(false)`, references can no longer be bootstrapped — the test fails forever with no artifact produced, reading like a rendering bug.
- **Evidence**: `RecordSnapshotTrait+Init.swift:21-23` maps `false` → `.never`, locked in by `RecordSnapshotTraitTests.swift:35-37`. Pointfree's own bridging (`SnapshotTestingConfiguration.swift:220-224`) maps `false` → `.missing`, which is also this package's no-trait default (`RecordSnapshotTrait.swift:10`). The migration CLI emits no record mapping today, so users hit this via manual rewrite.
- **Suggested fix**: Map `false` → `.missing` for pointfree parity, or deprecate the Bool overload in favor of explicit `.record(.never)`/`.record(.missing)`.
- **needs_dynamic_verification**: false

## 5. [LOW] Legacy trait-box overload ambiguity and behavior-stripping for custom SuiteTrait+SnapshotTestScoping shapes

- **File**: Sources/SnapshotTestingMacros/Traits/_Types/SnapshotTrait/__SuiteTraitBox.swift:12
- **Failure scenario**: a user-defined trait shaped `struct MyTrait: Testing.SuiteTrait, SnapshotTestScoping` (conforming directly to the Testing protocol rather than the package's marker protocol) hits an ambiguous-init compile error in macro-generated code the user never wrote, on the deprecated `@SnapshotSuite`/legacy macro path only. Separately, any trait routed through the `SnapshotTestScoping` inits is re-wrapped in `__TestScopingBox`, which forwards only `provideScope(performing:)` — `prepare(for:)`, `comments`, `isRecursive` are dropped (currently lossless for the package's own traits, but silently truncates richer custom traits).
- **Evidence**: `__SuiteTraitBox.swift:8-22` and `__TestTraitBox.swift:8-22` (four inits with no specificity ordering for the dual-conformance shape); generated call sites at `SnapshotSuite.swift:121-128`, `Test.swift:161-166`; `__TestScopingBox.swift:12-18` drops non-scoping behavior.
- **Suggested fix**: Add a disambiguating init for `any Testing.SuiteTrait & SnapshotTestScoping`, or document the required conformance shape in the box doc comments.
- **needs_dynamic_verification**: true

## 6. [IMPROVEMENT] Test-coverage gaps: decorator merge, cross-trait precedence, MainActor-hop round-trip, pointfree bridge interop

- **File**: Tests/SnapshotsUnitTests/Traits/DirectSwiftTestingSnapshotTraitScopingTests.swift:1
- **Description**: Untested behaviors: (1) additive decorator merging across suite/test scopes (a regression to plain shadowing would pass every existing test); (2) direct scoping tests cover only `ThemeSnapshotTrait`, macOS-gated, with no suite-vs-test-override or nested-suite coverage for Record/DiffTool/Sizes/Strategy; (3) `DiffToolSnapshotTraitTests.provideScope` asserts nothing; (4) no round-trip test for `ResolvedSnapshotRuntimeState.withAppliedValues` across all six task-locals — a future trait registered in `.current` but omitted from `withAppliedValues` would pass all tests while silently dropping the trait for non-MainActor tests; (5) nothing tests the pointfree bridge (env interop, `.pointfreeSnapshots` on a native test, counter stability across repeated in-process execution).
- **Evidence**: `DirectSwiftTestingSnapshotTraitScopingTests.swift:1-17` (macOS-only, theme-only); `DiffToolSnapshotTraitTests.swift:22-29` (assertion-free); `ResolvedSnapshotRuntimeStateTests.swift:5-29` (defaults only); `ExpectSnapshot+Traits.swift:26-35` (nested suite re-asserts same value as parent, can't catch inverted precedence); no test references `__SnapshotViewDecoratorConfiguration` merging across scopes.
- **Suggested fix**: Add a decorator-merge unit test, suite-vs-test/nested-suite override tests per task-local trait, a `withAppliedValues` round-trip test, a DiffTool scope assertion test, and an in-process double-invocation test asserting stable reference paths.
- **needs_dynamic_verification**: false
