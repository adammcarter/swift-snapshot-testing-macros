# 02 — Diagnostics & warnings to surface

**Summary.** The maintainer's stated priority is surfacing failures to users. The recent audit already closed the worst *silent-crash* and *silent-wrong* holes (the process-aborting `preconditionFailure` is now a recorded issue; extensions, interpolated display names, and several legacy-hardening shapes now diagnose). What remains is a **catalogue of compile-time fix-its** the legacy macro should emit but doesn't (issues #8–#12), one **typed-throws** gap (#21), two **trivia bugs** in existing fix-its (#24, and #23 now fixed), a **diagnostics refactor** (#25), and a handful of **runtime** messages that could be far more actionable. This doc inventories what exists, then gives a prioritized catalogue of new diagnostics with example messages and effort.

## Current diagnostic surface (what already fires)

Compile-time (`Sources/SnapshotsMacros`):
- `@SnapshotSuite` on an extension → hard error (`canContinueAfterSanityChecks.swift:19-33`).
- Interpolated/non-literal display name → hard error (`…:41-52`).
- Missing `@Suite` attribute → warning + insert fix-it (`SnapshotSuite.swift`, `Diagnostics.swift:30-56`).
- "Missing valid tests" → warning + stub/annotate fix-its (`Diagnostics.swift:59-131`) — issue **#25** wants this refactored (it's the most tangled factory).
- Non-initialisable instance function → warning + "make static" fix-it (`Test.swift`), trivia fixed in `c45f3a9` (issue **#23**).
- Multi-init / throwing-init / overloaded-container / param-attribute / `#if`-clause shapes → diagnosed or hardened (train-3 legacy lane `c3b8c87..36bf0bd`).
- Unsupported return type → **warn-and-skip** (train-3 `5b21a81`) — deliberately lenient so in-progress migrations still build. Issue **#10** wants this upgraded to a *per-return-type fix-it* (actionable, not just a skip).
- `#expectSnapshot` with no value/closure → error (`ExpectSnapshotMacro.swift`).

Runtime (`Sources/SnapshotTestingMacros`):
- No active test task (detached/GCD/XCTest host) → **recorded issue** (no longer a process crash) — `SnapshotRuntimePreconditions.swift`.
- Snapshot mismatch / missing reference → recorded issue via pointfree, attributed to the invoking test across the main-actor hop.
- Cross-case derived-name collision (`argument:`/config path) → recorded issue + skip (`SnapshotConfigurationNameCollisions`). **Gap:** the new per-case discriminator path does *not* route through this guard (round-3 finding; see `03`).
- Unrenderable AppKit size → recorded issue (train-3, no longer `fatalError`).

## Silent-wrongness gaps (highest value)

| Gap | Today | Should be |
|---|---|---|
| **#8** `@SnapshotTest` outside any `@SnapshotSuite` | peer macro returns `nil` silently — no test generated, no message | **error** + fix-it "Add `@SnapshotSuite` to the enclosing type" (or wrap). A user marks a function and nothing happens — the worst UX. |
| **#12** function takes args but no `configurations:`/`configurationValues:` supplied | generated code references a parameter that is never provided → cryptic compile error in expansion | **error**: "`func foo(state:)` declares parameters but no `configurations:`/`configurationValues:` were provided" + fix-it inserting the argument label. |
| **#11** `configurations:` supplied but the value isn't passed to the function parameter | mismatch → confusing generated code | **warning/error** + fix-it forwarding the value to the parameter (port from the SnapshotSuite path noted in the issue). |
| **#9** invalid `configurations:` (bare values, not `SnapshotConfiguration`) | type error deep in generated code | **error** + fix-it "Use `configurationValues:` instead" (the exact swap the user needs). |
| **#21** typed throws `throws(MyError)` on a `@SnapshotTest` func | only empty `throws`/no-throws supported; typed throws silently mis-handled | **error**: "`@SnapshotTest` supports untyped `throws` only" + fix-it removing the type. |
| per-case discriminator collision (round-3) | silent shared reference file | route the folded discriminator name through `SnapshotConfigurationNameCollisions` (see `03`, this is the one concrete *bug*). |

## Trivia / refactor bugs
- **#24** whitespace weirdness in `makeNewNodeWithSnapshotTestAnnotationsOnViableFunctions()` — the annotate-viable-functions fix-it inserts attributes with inconsistent trivia (same class as the #23 bug just fixed). **S.** Audit every `DeclModifierSyntax`/`AttributeSyntax` insertion for leading/trailing trivia; add golden fixtures.
- **#25** refactor `missingValidTests()` (`Diagnostics.swift:59-131`) — the largest, least-testable factory; split per-fix-it, unit-test each. **M**, unblocks confident future diagnostic work.

## New-diagnostic catalogue (prioritized)

**P1 (silent → loud, small):**
1. #8 error+fix-it `@SnapshotTest` needs an enclosing `@SnapshotSuite` — **S**.
2. #21 typed-throws rejection + fix-it — **S**.
3. #9 invalid-`configurations:`→`configurationValues:` fix-it — **S**.
4. #11 configurations-value-not-forwarded fix-it — **S**.

**P2 (structural):**
5. #12 args-without-configurations error+fix-it — **M**.
6. #10 per-return-type fix-its (upgrade the warn-and-skip to name the fix for `some View`/`UIView`/…) — **M**.
7. #24 trivia audit of all fix-it insertions + goldens — **S**.
8. #25 `missingValidTests` refactor — **M**.

**P3 (runtime QoL):**
9. Configurable snapshot **timeout** — the hardcoded `timeout: 5` in `Asserter.swift:104` has a `#warning`; expose a `.timeout(_:)` trait (`Duration`). On timeout the message should name the trait. — **S/M** (also in `04`).
10. **Richer failure comments** — when a reference is missing vs. mismatched, the recorded `Comment` could link the artifact path and suggest `--record`/the record workflow. — **S**.
11. **Zero-size render** already throws `SizeError`; ensure the message tells the user *which* trait/size produced it and suggests `.sizes(.fixed(...))`. — **S**.

## Principle
Every place the library can produce a **broken/empty/overwritten** artifact from a plausible user mistake should emit a diagnostic instead. The audit closed the crashes; this catalogue closes the *silent* wrongs, which are worse than crashes because they pass CI. Order of attack: P1 (four small silent→loud wins) → #25 refactor (unblocks the rest) → P2 → P3.
