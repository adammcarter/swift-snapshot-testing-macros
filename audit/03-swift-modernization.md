# 03 — Swift language & API modernization

**Summary.** The codebase is already Swift-6 clean (strict concurrency, `sending`, `@Sendable`) and survived a hard audit. The modernization opportunities are therefore about *craft and robustness*, not compile errors: consolidating the six-plus trait `@TaskLocal`s behind one structured value, replacing the **reflection-on-private-`Test.Case`** hack with a supported mechanism, documenting/tightening the seven `@unchecked Sendable` boxes, and adopting `Duration`/parameter-packs/typed-throws where they remove real duplication. One item is a **latent bug** (the per-case discriminator collision guard — see below and `02`).

## Latent bug (fix first)
**Per-case discriminator skips the collision guard.** `SnapshotExecutionContext.swift:44` folds a lossy-normalized discriminator into the unnamed reference name, but unlike the `argument:` path (`ExpectSnapshotAdapter.swift:765-793`) it never routes through `SnapshotConfigurationNameCollisions`. Two case values normalizing identically (`"v1.0"` / `"v1 0"` → `"v1-0"`) silently share one reference file. **Fix:** register the folded name through the same guard; record an issue + skip on conflict. **S**, high value — it's the one concrete defect in this lane and it reintroduces the exact harm the guard exists to prevent.

## @TaskLocal modelling

Today trait state is six independent `@TaskLocal` statics (record, theme, sizes, strategy, diffTool, decorator config), each set by its trait's `provideScope` and read back by `ResolvedSnapshotRuntimeState.current`, then re-applied one-by-one across the main-actor hop.

- **Safe win — one structured config task-local.** Collapse the six into a single `@TaskLocal static var current: SnapshotResolvedConfig` (a `Sendable` struct). `ResolvedSnapshotRuntimeState` already *is* that struct in spirit — it snapshots all six. Benefits: one `withValue` instead of six nested ones (the `withAppliedValues` pyramid), atomic inheritance, no risk of a future trait forgetting to participate in the snapshot. **M**, low risk (internal), improves the most-audited area. Keep the per-trait public factories; only the storage changes.
- **`SnapshotAttemptToken`** (`@unchecked Sendable`, `SnapshotAttemptToken.swift:23`) is sound but its lock-guarded mutable context could be an `actor` or a `Mutex` (Swift 6.0 `Synchronization.Mutex`) for a checked invariant. **S**, cosmetic.

## The `Test.Case` reflection hack (robustness, medium priority)

`SnapshotCaseDiscriminator.swift` reads argument values by `Mirror`-walking `Test.Case`'s private `_kind` payload because the toolchain exposes neither `Test.Case.arguments` nor `.id` publicly or via `@_spi`. Round-3 confirmed it **degrades safely to `nil`** (no crash) on a layout mismatch, but a `nil` there silently reverts to the round-2 collision on any toolchain whose layout differs from the CI matrix.

Options, best-first:
1. **File/track a swift-testing request** for public/SPI access to a case's arguments or a stable case identity; adopt when available. (The project already tracks upstream issues — #97, #40.)
2. **Derive the discriminator without reflection** where the value is in hand — the `argument:`/`configuration:` overloads already carry the value; only the *bare `#expectSnapshot` inside a parameterized body* needs the case identity. Consider requiring/encouraging `argument:` for parameterized bodies and diagnosing the bare form, sidestepping reflection entirely.
3. **Pin the reflection with a canary test** across the CI matrix so a layout change fails loudly instead of silently — cheap insurance until (1) lands. **S**, do this now regardless.

## `@unchecked Sendable` box inventory (7)

Each should carry a one-line invariant comment; most already do post-audit. Review:
- `MainActorResultBox` (`StrategyAssertionRequestGenerator.swift:158`) & `SyncMainActorResultBox` (`ExpectSnapshotAdapter.swift:30`) — smuggle non-`Sendable` AppKit results out of a *synchronous* main-thread closure. Invariant documented. Could unify into one generic helper. **S.**
- `UncheckedSendableBox` (`ExpectSnapshotAdapter.swift:16`) — generic value transfer; ensure each use still needs it after the adapter refactor. **S.**
- `SnapshotExecutionContextNameState`, `SnapshotConfigurationNameCollisions`, `SnapshotAttemptToken` — lock-guarded mutable registries; candidates for `Mutex`. **S.**
- `ApplyLock` (`ApplyLock.swift:26`) — wraps a file descriptor; invariant is the flock. Fine.

## Concurrency bridging

`ExpectSnapshotAdapter`'s `runOnMainActor` uses `Thread.isMainThread ? assumeIsolated : DispatchQueue.main.sync`. The async overloads were routed onto a proper bridge in the audit, but the **sync** path still blocks via `main.sync`. Low priority (snapshotting is inherently synchronous/main-actor), but worth a comment that this is deliberate and a note that a future all-async API could drop it. **S**, doc-only.

## Modern-API opportunities

- **Parameter packs (safe-ish, medium).** The tuple-config overloads are hand-written for arity 2 and 3 (`SnapshotConfiguration<(A,B)>`, `<(A,B,C)>`). Swift parameter packs (`each`) could express these once for all arities and delete the duplication — but macro-generated call sites and `String(describing:)` naming need care. **M**, medium risk; prototype behind tests.
- **`Duration` time limits (#28).** Add a `Duration`-based `.timeLimit` helper that converts to swift-testing's `.minutes` on the fly (seconds support). **S.** (Also `04`.)
- **`Strideable`/`RangeExpression` values (#45).** `configurationValues` currently takes a `Collection`; accept `stride(...)`/ranges directly. **S.** (Also `04`.)
- **Typed throws (#21).** Diagnose `throws(E)` at the macro (see `02`); no runtime change. **S.**
- **Lazy `IfConfig` properties (#22).** `SnapshotSuite.TestBlock.IfConfig` computes values on init even when there's no `#if`. Make them `lazy`/optional. **S**, low value but clean.
- **`Mutex` (Synchronization).** Replace `NSLock`-in-`@unchecked Sendable` with `Mutex<State>` for compiler-checked exclusivity. **S–M** across the registries.

## Bigger refactors (schedule deliberately)
- **Migration rewriter text heuristics.** The rewriter is largely `SwiftSyntax` now, but round-3 flagged remaining control-flow shapes (do/catch, labeled statements) the descent misses. Move any residual string logic to a full `SyntaxRewriter` visitor. **L.**
- **Trait config unification** (above) — the single highest-leverage internal cleanup.

## Sequencing
1. Fix the discriminator collision-guard bug (**S**, it's a real defect).
2. Add the reflection canary across the matrix (**S**, insurance).
3. Structured trait task-local (**M**, biggest craft win).
4. Small modern-API wins bundled with their feature issues (#28/#45/#21/#22).
5. `Mutex` sweep + parameter-pack prototype when there's slack.
