# 03 — Swift language, API modernization & code craft (deep)

**Audit date:** 2026-07-10
**Scope:** `Sources/SnapshotTestingMacros`, `Sources/SnapshotsMacros`,
`Sources/SnapshotMigrationSupport`, the supported Xcode matrix, and the focused audit/test evidence
already on `snapshot-helpers`.

## Executive verdict

The runtime is already Swift-6 strict-concurrency clean, and the adapter's hard part is sound: it
captures task-local configuration before the synchronous main-queue hop, rebinds it on the main
actor, carries failures back as `Sendable` values, and records them on the owning test task. The best
modernization work is therefore **not** a broad rewrite. It is four precise slices:

1. remove the private-layout `Mirror` walk for `Test.Case` arguments in favour of Swift Testing's
   existing SPI, compiler-gated for its Swift 6.1/6.2 shape change;
2. fix the case-identity collision bypasses and trait-less multi-assertion naming hole before doing
   cosmetic concurrency cleanup;
3. consolidate the six trait task-locals only as a tested, behaviour-preserving internal refactor;
4. finish the few syntax-driven macro/migration edges that still yield ambiguity or silently
   non-compiling migrated output.

The lighter baseline contained one stale defect and one incorrect premise. Commit `7460647` already
routes per-case discriminator names through the collision guard, so that is **closed**, not a latent
bug. More importantly, the supported Swift Testing sources *do* expose case arguments under SPI;
private reflection is avoidable today.

## Corrections to the lighter baseline

| Baseline claim | Current evidence | Verdict |
| --- | --- | --- |
| Per-case discriminator bypasses collision detection | `SnapshotExecutionContext.swift:131-159` and `ExpectSnapshotAdapter.swift:1117-1142` now register the folded name; tests cover distinct values normalizing to one name | **Fixed at `7460647`** |
| Swift Testing exposes no case arguments publicly **or under SPI** | Swift 6.1 and 6.2 both expose `Test.Case.arguments` under `Experimental` / `ForToolsIntegrationOnly` SPI; only `[Argument]` vs `[Argument]?` differs | **Incorrect; replace reflection with a gated SPI adapter** |
| One structured task-local is a small safe win | It touches every trait scope, decorator composition, direct trait reads, capture/rebind, and precedence tests | **Worthwhile M refactor, but not a first fix** |
| All seven production `@unchecked Sendable` sites should become `Mutex` | There are seven production sites plus one test helper. Direct `Synchronization.Mutex` is macOS 15+/iOS 18+, while this package declares iOS 15. Two production boxes deliberately carry non-`Sendable` UI values | **Use one iOS-15-compatible `Locked<State>` boundary for synchronous state; do not run a blind `Mutex` sweep** |
| Typed throws should be rejected as unsupported | `FunctionSignatureSyntax.isThrows` detects the throws clause, including `throws(E)`, and generated calls receive `try`; the generated test widens the effect to ordinary `throws` | **Coverage/policy gap, not a current compile defect** |

Swift Testing source evidence:

- [Swift 6.1 `Test.Case.arguments`](https://github.com/swiftlang/swift-testing/blob/swift-6.1-RELEASE/Sources/Testing/Parameterization/Test.Case.swift)
  is an SPI `[Argument]`.
- [Swift 6.2 `Test.Case.arguments`](https://github.com/swiftlang/swift-testing/blob/swift-6.2-RELEASE/Sources/Testing/Parameterization/Test.Case.swift)
  is an SPI `[Argument]?`; `isParameterized` is public.
- The proposal for a simpler public value array remains
  [swift-testing PR #1350](https://github.com/swiftlang/swift-testing/pull/1350).

Deployment evidence:

- Both manifests declare macOS 15 and iOS 15. The current
  [Synchronization `Mutex`](https://developer.apple.com/documentation/synchronization/mutex)
  is available from macOS 15 and iOS 18, so using it in shared runtime code would silently raise
  the effective iOS floor.
- The Swift 6.2.1 `MainActor.assumeIsolated` result is still constrained to `Sendable`; the source
  comment saying this restriction lasts only “until Swift 6.2” is stale. The narrow AppKit transfer
  boundary still has a purpose.

---

## Current correctness findings

### 1. [Medium] Trait-less tests with two unnamed assertions still resolve one reference

`TaskLocalSnapshotExecutionContext.resolveContext` deliberately returns a fresh context when no
`SnapshotAttemptToken` is bound (`TaskLocalSnapshotExecutionContext.swift:40-57`). A token is bound by
snapshot trait scoping, not by a bare native `@Test`. Therefore this reasonable shape:

```swift
@Test
func cards() {
  #expectSnapshot(CompactCard())
  #expectSnapshot(ExpandedCard())
}
```

creates two fresh contexts. Both derive `cards`, both restart the reference identifier at `.1`, and
both target the same reference. The limitation is accurately documented in the source, but it is
still a user-visible correctness hole in the standalone `#expectSnapshot` API.

**Fix direction (S/M, compatibility risk medium):** first add an integration regression that proves
the two files are distinct. Then make the no-token fallback include a stable call-site discriminator
(`fileID + line + column`, shortened with the repo's stable hash) in the effective reference key. That
churns existing trait-less names, so ship a migration note. Reintroducing a process-global task cache
would repeat the allocator-reuse bug this branch removed; do not do that.

```swift
let fallbackIdentity = StableCallSite(fileID: fileID, line: line, column: column)
let context = SnapshotExecutionContext(
  function: function,
  fallbackCallSiteDiscriminator: fallbackIdentity.shortHash
)
```

An explicit `.snapshots` scoping trait is a lower-compatibility alternative, but it makes the
standalone macro surprisingly unsafe unless users remember a second API. Prefer making the macro's
default path correct.

### 2. [Medium robustness] Private `Test.Case._kind` reflection can be removed now

`SnapshotCaseDiscriminator.argumentValues` (`SnapshotCaseDiscriminator.swift:73-123`) currently
expects five private labels/shapes: `_kind`, enum case `parameterized`, payload field `arguments`, a
collection, and each element's `value`. Any toolchain layout change returns `nil`; the fallback does
not crash, but it silently removes case disambiguation and reinstates cross-case reference sharing.

The current unit canary is useful (`SnapshotCaseDiscriminatorNamingTests.swift:79-116`), but
`.github/workflows/run-tests.yaml` runs only four filtered suites on Xcode 16.3–26.5 and does **not**
run this one. The matrix therefore does not actually guard the private-layout dependency.

The supported toolchains already provide a better seam. Use the SPI and gate only the source-level
optional change:

```swift
@_spi(ForToolsIntegrationOnly) import Testing

private static func argumentValues(from testCase: Test.Case) -> [Any]? {
  guard testCase.isParameterized else { return nil }

  #if compiler(<6.2)
  let arguments = testCase.arguments
  #else
  guard let arguments = testCase.arguments else { return nil }
  #endif

  return arguments.map(\.value)
}
```

**Value:** correctness and diagnosability. An SPI shape change becomes a compile failure in the matrix
instead of silent runtime name corruption.
**Effort:** S.
**Risk:** low/medium; SPI remains non-public, but this package already deliberately imports
pointfree internals and pins versions. Keep the matrix canary, add it to every Xcode row, and track
upstream PR #1350. If SPI use is rejected as policy, at minimum use public `isParameterized` to fail
closed with an issue when extraction fails rather than returning an undiscriminated name.

### 3. [Medium] Case identity has two collision-guard bypasses

The existing collision fix only runs after `SnapshotCaseDiscriminator.identity` returns an identity.
Two inputs evade or defeat that protection:

1. values such as `""` and `"!!!"` normalize to an empty component; line 45 returns `nil`, so the
   parameterized case falls back to the undiscriminated base name and never enters the guard;
2. `rawDescription` flattens arguments and tuple elements with the same `"-"` separator, so
   `("a-b", "c")` and `("a", "b-c")` both become `"a-b-c"`. The guard then mistakes distinct
   cases for a repetition of one value.

**Fix direction (S/M, compatibility risk medium):** preserve argument/component structure in the
registry identity (for example, a length-prefixed encoding or a typed array key), and give an empty
visible discriminator a deterministic hashed fallback or record an attributed issue and skip. Add
real parameterized tests for empty/punctuation-only values and delimiter-ambiguous tuples before
changing production naming.

### 4. [Low] The collision registry is process-lifetime and insert-only

`SnapshotConfigurationNameCollisions.shared` owns a locked dictionary and never evicts entries
(`SnapshotConfigurationNameCollisions.swift:24-49`). Growth is bounded by the number of distinct
call-site/occurrence/derived-name triples in one test process, so this is not an urgent leak, but it
is the only remaining process-lifetime assertion registry.

Moving it onto `SnapshotAttemptToken` would be **wrong**: collisions are detected *between* attempts
for distinct parameterized cases. The honest choices are:

- document the process lifetime and accept the bounded run-sized cache (S, no behaviour risk); or
- replace lossy names with `normalizedName + stableHash(structurallyEncodedComponents)` so
  collisions are practically eliminated without global state (M, high reference-churn/compatibility
  risk and ADR-worthy).

Changing the lock primitive does not solve lifetime.

---

## Task-local modelling

### What exists and why it is correct

Six package values are independently task-local: sizes, theme, strategy, record, diff tool, and the
combined padding/background decorator. `ResolvedSnapshotRuntimeState.current` also captures
pointfree's SPI `SnapshotTestingConfiguration.current` before the synchronous queue hop.

```text
test task
  │ capture 6 package values + pointfree configuration
  ▼
ResolvedSnapshotRuntimeState
  │ DispatchQueue.main.sync loses task-local inheritance
  ▼
main actor
  │ rebind context + pointfree + 6 package values
  ▼
render / verify ── SnapshotFailure values ──► owning test task records issues
```

This is not theoretical: `ResolvedSnapshotRuntimeStateTests`,
`AmbientPointfreeConfigurationTests`, and `SnapshotIssueAttributionTests` pin the capture/rebind and
failure-attribution behaviour. The async path uses a structured `await`, preserves the task, and
still reuses the same isolated tail.

### Consolidate storage, not public traits

The current pyramid in `ResolvedSnapshotRuntimeState.withAppliedValues` has a real maintenance risk:
every new trait must be added to its own `@TaskLocal`, to capture, and to rebind. Forgetting any one
step silently loses the trait off-main. A single internal value makes that invariant atomic while
leaving `.theme`, `.sizes`, `.record`, and every public trait unchanged.

```swift
struct SnapshotRuntimeConfiguration: Sendable {
  var sizes: [SizesSnapshotTrait.Size] = [.init(width: .minimum, height: .minimum)]
  var theme: ThemeSnapshotTrait.Theme = .all
  var decorator: __SnapshotViewDecoratorConfiguration?
  var strategy: StrategySnapshotTrait.Strategy = .image
  var record: RecordSnapshotTrait.RecordKind?
  var diffTool: DiffToolSnapshotTrait.DiffTool?

  @TaskLocal static var current = Self()

  func setting<Value: Sendable>(
    _ keyPath: WritableKeyPath<Self, Value>,
    to value: Value
  ) -> Self {
    var copy = self
    copy[keyPath: keyPath] = value
    return copy
  }
}

public func provideScope(performing function: () async throws -> Void) async throws {
  let next = SnapshotRuntimeConfiguration.current.setting(\.theme, to: theme)
  try await SnapshotRuntimeConfiguration.$current.withValue(next, operation: function)
}
```

`ResolvedSnapshotRuntimeState` then carries two fields: the package configuration and pointfree's
configuration, and rebinds each once. Decorator scopes must copy the current configuration before
changing one field so nested padding/background traits preserve each other.

**Value:** removes omission pressure, shrinks the seven-deep rebind pyramid, and makes a complete
runtime configuration a first-class testable value.
**Effort:** M.
**Risk:** medium: nested suite/test precedence and decorator composition are behaviour. Keep the
existing public factories, land behind precedence tests, and do not combine this with new traits.

### `SnapshotAttemptToken` is the right lifetime boundary

The attempt token owns exactly one lazily-created execution context and inherits into structured
child tasks. That design fixed the former raw-task-pointer cache and should stay. An `actor` would make
the synchronous name/reference APIs async for no product value. Direct `Synchronization.Mutex` is
not deployment-neutral here: its iOS 18 availability conflicts with the package's iOS 15 floor.
Consolidate the invariant behind one compatibility wrapper instead:

```swift
final class SnapshotAttemptToken: Sendable {
  private let context = Locked<SnapshotExecutionContext?>(nil)

  func executionContext(function: StaticString) -> SnapshotExecutionContext {
    context.withLock { value in
      if let value { return value }
      let created = SnapshotExecutionContext(function: function, caseIdentity: caseIdentity)
      value = created
      return created
    }
  }
}
```

`Locked<State>` can keep the current `NSLock` implementation and centralize its single audited
`@unchecked Sendable` invariant. It can switch internally to `Mutex` only in a target/deployment
configuration where that availability is valid.

**Effort:** S/M. **Risk:** low after the supported Xcode matrix proves iOS 15 remains buildable.

---

## Complete `@unchecked Sendable` inventory (7 production + 1 test helper)

| Site | Invariant | Assessment | Modernization |
| --- | --- | --- | --- |
| `ExpectSnapshotAdapter.UncheckedSendableBox` | Exclusive one-way handoff of a possibly non-`Sendable` view or builder into a synchronous/structured main-actor hop; producer never touches it again | Sound and well documented; the type system on the oldest supported toolchains cannot express this region transfer | Keep one centralized unchecked boundary. Re-test whether `sending` removes it only after dropping Swift 6.1 |
| `ExpectSnapshotAdapter.SyncMainActorResultBox` | `main.sync` gives write-before-read ordering; lock protects a single `Result` slot | Sound; actual `T` is `[SnapshotFailure]`, which is `Sendable`, and a strict Swift 6.2.1 probe can return `Result` directly from `DispatchQueue.main.sync` | Prefer deleting the box if the Swift 6.1/6.2 Apple matrix accepts the direct `Result`; otherwise use `Locked<Result<…>?>` |
| `StrategyAssertionRequestGenerator.MainActorResultBox` | `MainActor.assumeIsolated` executes synchronously on the current main thread; an `NSView`/`NSImage` never crosses concurrently | Narrowly sound; its “until Swift 6.2” comment is stale because the 6.2.1 result remains `Sendable`-constrained | Keep one specialized unchecked synchronous AppKit transfer helper until the minimum compiler signature permits removal |
| `SnapshotAttemptToken` | `NSLock` protects lazy context creation; immutable case identity | Sound | `Locked<SnapshotExecutionContext?>` |
| `SnapshotExecutionContextNameState` | One lock protects `usedNames`, reference counts, and occurrence counts as one state unit | Sound | One `Locked<State>` and fewer lock/state fields |
| `SnapshotConfigurationNameCollisions` | One lock protects a process-global dictionary | Thread-safe; lifetime is intentionally/accidentally process-wide | `Locked<State>` plus typed keys; decide lifetime separately |
| `SnapshotMigrationSupport.ApplyLock` | Kernel `flock` owns inter-process exclusion; `releaseGuard` makes descriptor close idempotent | Mostly sound after the stale-lock race fix, but a missed explicit `release()` keeps the descriptor until process exit | `Locked<Bool>` for release state and `deinit { release() }` as the ownership safety net |
| Test-only `SnapshotIssueAttributionTests.RenderProbe` | One lock protects its two optional observations | Sound test helper | Reuse `Locked<State>` or isolate the probe to `@MainActor` |

Do not replace these with actors wholesale. All hot operations are synchronous, tiny critical
sections; actor conversion would infect rendering and migration APIs with suspension without making
the invariants clearer. A compatibility wrapper does not make the underlying lock magically checked;
it reduces seven scattered unchecked invariants to one reviewable implementation while preserving
iOS 15.

---

## Concurrency and failure transport

### Keep the value-carrying failure boundary

`SnapshotFailure` is the correct design. Swift Testing attribution is task-local; recording inside
the `DispatchQueue.main.sync` callout loses `Test.current`, `Test.Case.current`, and
`withKnownIssue`. Returning `[SnapshotFailure]` and recording at `ExpectSnapshotAdapter.swift:1053`
and `:1076` preserves ownership. Do not move `Issue.record` back into the asserter.

### Sync and async paths should remain distinct at the boundary

```text
sync API   ─► main thread? assumeIsolated : DispatchQueue.main.sync ─► result box
async API  ─► await @MainActor isolated tail                         ─► direct result
both       ─► same render/verify implementation                     ─► caller records
```

The synchronous API necessarily blocks until rendering finishes. The modern long-term direction is
to make async overloads the primary surface and treat the sync bridge as compatibility code, not to
hide `main.sync` behind an unstructured `Task` or semaphore. The current `Thread.isMainThread` guard
also prevents a self-deadlock.

### `sending` is already used where it helps

Direct values use `sending` (`expectSnapshot.swift` and `ExpectSnapshotAdapter.swift`); closures are
`@Sendable` where the surrounding API can require it. The remaining unchecked box exists because
Swift 6.1 region analysis rejects captures the newer compiler accepts. Re-probe it when the minimum
toolchain moves; until then, the documented exclusive-handoff invariant is better than availability
branches scattered through 25 overloads.

---

## Macro craft and generated code

### What is already good

- `ExpectSnapshotAdapter` now funnels the 25 public macro overloads through four effect cores and one
  main-actor tail; the overload accounting and error policies are pinned by tests.
- The legacy macros use typed SwiftSyntax builders for declarations/calls in most high-risk places.
- Recent fixes already closed overloaded container names, parameter-only attributes, empty `#if`
  clauses, multi-initializer suites, throwing/async initializer effects, and malformed fix-it trivia.
- `ExpectSnapshotMacro` trims spliced nodes, so same-line comments cannot comment out generated
  arguments.

### Safe wins still open

#### A. Sole function references are syntactically ambiguous

`#expectSnapshot(makeView)` is parsed by `ExpectSnapshotMacro.swift:13-40` as a direct value because
the first unlabeled expression is not a closure literal. The generated call then fails later with a
poor overload error. A syntax-only macro cannot know whether a `DeclReferenceExprSyntax` names a view
value or a zero-argument function.

**Fix (S, low risk):** add an explicit labelled form and document it for non-literal builders:

```swift
public macro expectSnapshot<V: View>(
  named: String? = nil,
  makeValue: @escaping () async throws -> V
)
```

Keep trailing closure syntax for literals. Add macro fixtures for `makeValue: makeView` and retain the
old unlabeled overload for source compatibility.

#### B. Typed throws works, but lacks a pinned compatibility policy (#21)

`FunctionSignatureSyntax.isThrows` checks only for a throws specifier; `throws(MyError)` is treated as
ordinary throwing code. Generated legacy test functions are always untyped `async throws`, and the
builder inserts `try`. That widening is legal: the original function retains its typed contract and
the generated test may expose the broader `throws` effect.

**Fix (S, tests first):** add expansion and Apple-toolchain compile fixtures for typed-throwing
functions and initializers across the supported matrix. Treat rejection as a separate product policy
only if the maintainer explicitly wants issue #21's older restriction; do not diagnose currently
valid generated code as a correctness fix. **Risk:** low for coverage; source-breaking if rejection
is chosen later.

#### C. Generic legacy suites/functions need a direct diagnostic

There is still no `genericParameterClause` / `genericWhereClause` guard in `SnapshotsMacros`.
Generated `Suite()` calls cannot infer a generic suite type, and Swift Testing does not accept the
generated nested test shape reliably. **Fix:** error-and-skip at the attached macro with the generic
clause highlighted. **Effort S, risk low.**

#### D. Constrain `SnapshotConfiguration.none`

`SnapshotConfiguration<T>.none` returns `SnapshotConfiguration<Void>` for every `T`, so
`SnapshotConfiguration<Int>.none` compiles but changes the generic type. Move it to:

```swift
extension SnapshotConfiguration where T == Void {
  public static var none: Self { .init(name: nil, value: ()) }
}
```

**Value:** API correctness. **Effort S, risk low** (source errors only for nonsensical explicit uses).

#### E. Optional configuration names should describe the payload, not `Optional(...)`

`SnapshotConfigurationParser.parse([T])` uses string interpolation. For `[String?]`, a non-nil value
becomes `Optional("value")`, producing an awkward normalized reference. A more-specific optional
overload can map `.some` to the wrapped description and `.none` to `nil`/`none`. **Effort S, risk
medium** because references rename; ship as an opt-in or migration release.

#### F. Generated attribute filtering must match names, not prefixes

`Test.swift:463-472` and `SnapshotTest.swift:255` use `hasPrefix` on rendered attribute text.
That can treat `@MainActorish` as `@MainActor` and `@availableFeature` as `@available`, while
module-qualified spellings need deliberate handling. Reuse the existing syntax-aware attribute-name
helper and compare the terminal identifier exactly. Add misleading-prefix and qualified-name macro
fixtures. **Effort S, risk low.**

### Bigger macro refactor: reduce string-emitted syntax at the edges

`ExpectSnapshotMacro` still assembles the whole expansion as a string, and legacy generator helpers
wrap `await`/`try` through `ExprSyntax(stringLiteral:)`. These paths are test-covered, so this is not a
bug, but typed builders make argument labels and trivia structural rather than textual.

**Refactor (M):** build the final `FunctionCallExprSyntax`, add labelled arguments as
`LabeledExprSyntax`, and wrap effects with syntax nodes. Do it only after the open diagnostics above;
otherwise a large representation-only diff obscures behaviour.

---

## Migration rewriter modernization

`SnapshotMigrationRewriter.swift` is now syntax-first where it matters: it parses with SwiftParser,
collects declarations using a `SyntaxVisitor`, applies UTF-8-positioned edits, and rewrites
configuration initializers through AST nodes. The old blind initializer regex bug is fixed. The
remaining problem is responsibility and a few shared blind spots, not "replace the regex rewriter"
wholesale.

### Current correctness gaps to fix first

1. **do/catch and labelled configuration control flow** —
   `collectConfigurationResultExpressions` descends through return/guard/if/switch/ternary but drops
   `DoStmtSyntax` and `LabeledStmtSyntax`. Bare `.init(...)` inside those shapes can escape both the
   typer and its safety check, yielding non-compiling output reported as migrated. **S/M, low product
   risk; add failing rewriter and type-check canary tests first.**
2. **ambiguous first `@SnapshotSuite` argument during trait folding** — a non-literal display name
   and an explicitly-based trait are not distinguishable syntactically. Current classification can
   drop `CustomTrait()`/`MyTraits.dark`. Fail closed with an "ambiguous first argument" skip rather
   than guessing. **S, low risk.**
3. **remaining string decisions** — nil/type-context checks, literal-name extraction, and
   zero-argument function detection still use `contains`/regex around an already-parsed expression
   and, for function lookup, whole-source text without lexical scope. Comments, string literals, or
   a same-named declaration in another type can change the migration decision. Drive them from syntax
   nodes and scope-aware declaration keys so strings such as `"nil-state"` and `"func values()"`
   cannot affect typing decisions. Fail closed on multiple plausible declarations. **M, medium
   regression risk.**

### Split by responsibility after the fixes

The file mixes orchestration, collection/models, configuration analysis, body rendering, source
location, and edit application. A behaviour-preserving split is safer than a new monolithic
`SyntaxRewriter`:

```text
SnapshotMigrationRewriter      orchestration + outcomes
├── LegacyDeclarationCollector visitor + models
├── ConfigurationsRewriter     expression analysis / typed initializer edits
├── LegacyBodyRenderer         generated body syntax/trivia
└── TextEditApplier            ordered UTF-8 edits + overlap checks
```

**Effort:** M/L. **Risk:** medium. Keep golden output tests and add compile/type-check fixtures; a parse
check alone cannot catch an untyped `.init(...)`.

---

## Modern API opportunities

| Opportunity | Concrete move | Value | Effort / risk |
| --- | --- | --- | --- |
| Finite `Sequence` configuration values (#45) | Add a more-general `Sequence` path while retaining the more-specific `Collection` overloads; materialize once and cover `stride`, range, set, single-pass sequence, and overload resolution | Makes `stride(...)` work; ranges already work today. Document that input is consumed once and must be finite | S/M / medium: arbitrary `Sequence` permits infinite input and can alter overload ranking |
| `Duration` snapshot timeout | Add `.snapshotTimeout(_ duration: Duration)` and convert once at pointfree's `TimeInterval` boundary; remove the 5-second `#warning` | Type-safe, tunable slow-CI behaviour | S/M / low |
| `Duration` time-limit helper (#28) | Convert/round to Swift Testing's supported `TimeLimitTrait` representation and document granularity | Consistent Swift-native call site | S / low |
| `ContinuousClock` for apply-lock timeout | Replace `Date()` deadline comparison with a monotonic `ContinuousClock.Instant`; keep the sync sleep loop or make a separately async API | Wall-clock changes cannot extend/shorten apply-lock waits | S / low |
| Parameter packs | Prototype `SnapshotConfiguration<(repeat each Value)>` plus a `(repeat each Value) -> V` builder to replace tuple-2/tuple-3 overload families | Removes repeated public/runtime/macro declarations and unlocks arity 4+ | M/L / medium-high; spike across every compiler row |
| Structured configuration task-local | One internal config value, one capture, one rebind | Prevents future trait omission | M / medium |
| iOS-15-compatible `Locked<State>` | Consolidate synchronous lock-protected holders behind one audited boundary; use `Mutex` internally only where deployment permits | Clearer invariants without raising the package floor | S/M / low after Apple matrix proof |

### #22 (`IfConfig` lazy properties) is not currently a useful optimization

`SnapshotSuite.TestBlock.IfConfig.init` immediately transforms the `IfConfigDeclSyntax`, and its
caller immediately reads `.expression`. Making the field lazy only adds mutation/exclusivity or a
reference box; it avoids no work in the current call graph. Close/deprioritize #22 unless profiling
finds repeated construction. The useful cleanup is the existing `#warning` at `IfConfig.swift:39`:
express the empty/non-empty clause with a normal syntax-builder branch and delete the trivia "faff".

---

## Source `#warning` / TODO inventory

| Site | Real action |
| --- | --- |
| `Asserter.swift:104` — configurable timeout | Implement the `Duration` snapshot-timeout trait; delete the warning |
| `SizesSnapshotTrait+Length.swift:10` — intrinsic vs preferred minimum | Add the additive sizing enum described in `04`; keep bare `.minimum` as compatibility spelling |
| `PaddingSnapshotTrait.swift:49` — hard-coded default padding 16 | Either derive a platform default with a render probe or document 16 as this library's stable default; a compiler warning is not a design |
| `IfConfig.swift:39` — empty-clause/trivia construction | Mechanical syntax-builder refactor; keep the fixed source-empty branch behaviour |
| `SnapshotSuite/_Support/MacroContext.swift:5` — macro-generated member expressions | Track as a design note only; do not add another macro layer without a concrete duplication win |

These are four production `#warning`s plus one source TODO. The four
`#warning("Unsupported Kit")` occurrences under macro expansion fixtures are deliberate expected
payload and must remain. Warnings compiled into every consumer build are a poor backlog: convert
deferred production work to linked issues/comments or implement it; reserve `#warning` for an
actionable migration signal.

---

## Prioritized roadmap

### Safe wins

1. **Replace `Test.Case._kind` reflection with the compiler-gated SPI adapter** and run its canary on
   every Xcode matrix row.
2. **Pin the empty and structurally ambiguous case-identity failures**, then preserve component
   structure and fail closed when a parameterized identity cannot be produced.
3. **Write the failing trait-less two-assertion integration test**, then choose and document the
   stable call-site naming migration.
4. Fix the migration rewriter's do/catch + labelled-statement descent, ambiguous trait fold, and
   scope-insensitive text heuristics,
   driven by failing tests and a compile/type-check canary.
5. Add typed-throws compile coverage, exact attribute-name fixtures, and generic legacy diagnostics;
   constrain `SnapshotConfiguration.none`.
6. Add deliberate finite-`Sequence` support for `configurationValues`, adopt `ContinuousClock` for
   the lock deadline, add `ApplyLock.deinit`, and remove the four production `#warning`s through
   their owned slices.
7. Consolidate synchronous mutable state behind an iOS-15-compatible `Locked<State>`; retain the
   deliberate non-`Sendable` UI handoff boundary and delete the sync result box only if every Apple
   compiler row accepts direct `Result` transport.

### Bigger refactors — schedule separately

1. Consolidate package trait state into `SnapshotRuntimeConfiguration`, with precedence and ambient
   pointfree configuration tests as the gate.
2. Split `SnapshotMigrationRewriter` by responsibility after its current correctness gaps are fixed.
3. Prototype parameter packs across Xcode 16.3–26.5 before changing the public overload surface.
4. Move string-emitted macro expansions to typed builders only as a representation-only change.

The sequencing matters: the first four safe wins remove silent reference corruption and silent
non-compiling migration output. The larger refactors improve change safety, but none should delay
those correctness slices.
