# 01 — GitHub open-issue triage (deep)

**Scope.** All 26 open issues on `adammcarter/swift-snapshot-testing-macros`, each assessed
against source baseline **`c95fcd9`** ("docs: value & feature audit"), which sits on
top of the correctness-fix work in `f5d0037..7460647`. Every verdict below is backed by reading the
relevant source (cited `file:line`) or by a commit that demonstrably closed the gap. Where the code
could not answer a question, I ran the check (e.g. the `stride()` conformance test for #45) rather
than guess.

**What changed vs the earlier baseline.** Three findings were corrected after reading the source:

| # | Baseline said | Corrected verdict | Evidence |
|---|---|---|---|
| 8 | PARTIAL — "a `nil`-return path exists but **no diagnostic**" | A **warning diagnostic already exists** (added `1f9ef19`); what's missing is *error-vs-warning* decision + fix-its | `SnapshotTest.swift:83-95` |
| 12 | STILL-OPEN | **ALREADY-DONE** — parameterised-func-without-configs is now a hard error | `SnapshotTest.swift:160-172` (`1f9ef19`) |
| 45 | STILL-OPEN (good first issue), no root cause | STILL-OPEN, **root cause pinned**: `stride()` is `Sequence`-only, the `C: Collection` overload can't accept it | verified by compile check; `SnapshotConfigurationParser.swift:45-55` |

---

## Triage table (all 26)

| # | Theme | Verdict | Effort | Value | One-line action |
|---|---|---|---|---|---|
| 97 | external | EXTERNAL (swift-testing #1643) | — | — | Track upstream; CI runs 26.4 green. Keep open, annotate. |
| 40 | external | EXTERNAL (FB17207500) | — | med | Keep open pending Apple. |
| 64 | bug? | NEEDS-DECISION | M | med | Reproduce `UITableViewCell`; likely a UIKit-hosting doc note + optional helper. |
| 45 | configurations | STILL-OPEN (good first issue) | S | med | Add `Sequence` overloads so `stride()` works. |
| 28 | traits | STILL-OPEN | S | med | `Duration`-based `.timeLimit` seconds helper. |
| 26 | features | STILL-OPEN (architectural) | L | med-high | SwiftUI `ImageRenderer` host-free path — spike first. |
| 25 | diagnostics/hygiene | STILL-OPEN | M | low-med | Refactor `missingValidTests()` (still one 70-line builder). |
| 24 | diagnostics/bug | STILL-OPEN | S | med | Give the annotate-viable-functions fix-it correct trivia. |
| 23 | diagnostics/bug | **ALREADY-DONE** (`1a3323d`) | — | — | Verify fixture, **close**. |
| 22 | enhancement | OBSOLETE-ish / STILL-OPEN | S | low | `IfConfig` is already built on-demand; the wasteful-init premise is gone. Close or downscope. |
| 21 | diagnostics | STILL-OPEN | S | med | Diagnose `throws(E)` typed throws. |
| 20 | misc | NEEDS-DECISION | M | low-med | Make `@SnapshotTest` peer-expand a visible `Test`. UX call. |
| 18 | misc | **ALREADY-DONE** (render half, `94d11b6`+) | — | high | **Close** with the macOS-CI-record note. |
| 17 | features | STILL-OPEN (exploratory) | L | high | `#Preview ↔ suite` bridge — highest "loveable" ceiling. |
| 16 | traits | STILL-OPEN | M | high | `.record(.deleteStale…)` + explicit data-loss warning. |
| 14 | hygiene | **LARGELY-DONE** | S | low | Filename/naming logic now unit-tested — **close after gap scan**. |
| 13 | hygiene | **LARGELY-DONE** | S | low | 102 unit-test files now cover the helpers — **close after gap scan**. |
| 12 | diagnostics | **ALREADY-DONE** (`1f9ef19`) | — | — | Verify message, **close**. |
| 11 | diagnostics | STILL-OPEN | S | med | Fix-it: configs supplied but func takes no params. |
| 10 | diagnostics | STILL-OPEN | M | med | Per-return-type fix-its (pairs with warn-and-skip `e1ce4d6`). |
| 9 | diagnostics | STILL-OPEN | S | med | Fix-it: invalid `configurations:` → suggest `configurationValues:`. |
| 8 | diagnostics | PARTIAL (warning exists) | S | high | Decide error-vs-warning; add fix-its. |
| 7 | docs | STILL-OPEN | M | med | ADR: `@SnapshotTest` opt-in vs inference. |
| 6 | docs | STILL-OPEN | L | med | ADR backlog for existing decisions. |
| 2 | configurations | STILL-OPEN | M | med | `product`/zip combinators + explosion guard. |
| 1 | configurations | STILL-OPEN | M | med | Result-builder for `configurations`. |

Legend: **Effort** S ≈ <½ day · M ≈ 1–2 days · L ≈ multi-day/spike. **Value** = user-facing payoff.

---

## Close-immediately (already-done / obsolete, with evidence)

These five can be closed now (four verify-then-close, one is a moot premise). Evidence is concrete.

- **#23 — fix-it trivia for "instance functions on types that cannot be initialised."**
  Fixed by `1a3323d` ("give the *Make function static* fix-it correct trivia"). The diagnostic and
  its fix-it live at `Test.swift:351-363`; the trivia handling that #23 complained about is the
  block at `Test.swift:333-349` — it hoists the function/modifier's leading trivia onto the injected
  `static` keyword so the fix no longer fuses into `@SnapshotTeststatic`. **Action:** run the
  `testEnumInstanceFunction` expectation in `SnapshotSuiteTests+Diagnostics.swift`, confirm the
  expanded output is well-formed, close.

- **#12 — sanity check for a function with args when no configurations are expected.**
  Done by `1f9ef19`. `SnapshotTest.swift:160-172` now hard-errors: *"A parameterised '@SnapshotTest'
  function requires a 'configurations:' or 'configurationValues:' argument."* whenever the function
  has parameters but neither argument is supplied. That is exactly the mismatch #12 asked for.
  **Action:** confirm the error message reads well, close. (Note the *inverse* — configs supplied to
  a param-less function — is **#11**, still open.)

- **#18 — render mac screenshots with correct scale.**
  The render half is done: `94d11b6` renders AppKit snapshots at `size × displayScale` in an
  offscreen window, hardened by `0d89817` (restore caller appearance/layer-backing), `4b0fc72`
  (deactivate host constraints), `f048908` (reject unrenderable sizes). Code:
  `Generators/AppKitImageRenderer.swift`. The second half ("then run integration tests on Mac") is a
  CI/rebaseline concern, not a code gap — references are recorded on the CI runner (`ae45057`) and
  local macOS 27 will differ. **Action:** close the render item; if the Mac-integration run is still
  wanted, split it into a fresh CI-only issue rather than keeping this one open.

- **#13 / #14 — unit tests for helpers and file names.**
  `Tests/SnapshotsUnitTests` now holds **102** test files, including the naming/filename logic that
  #14 specifically called out: `SizesSnapshotTraitSizeNamingTests`, `SnapshotCaseDiscriminatorNamingTests`,
  `SnapshotConfigurationNameCollisionTests`, `ExpectSnapshotNamingTests`, and the rewriter parity
  suite `SnapshotMigrationRewriterNamingParityTests`. The "logic should be split out and unit-tested"
  ask (#14) is satisfied. **Action:** do one gap scan for any helper still exercised only via
  integration snapshots, file a narrow follow-up if found, close both.

- **#22 — lazy properties for `SnapshotSuite.TestBlock.IfConfig`** *(obsolete premise).*
  The issue's premise — "we won't always have an if config so always setting these values on init is
  wasteful" — no longer holds. `IfConfig.swift:4-19` is a struct with a **single** stored
  `ifConfigDecl`, and it is only ever constructed from an actual `IfConfigDeclSyntax`
  (`IfConfig.swift:75-84` only builds one when a `#if` member exists). There are no eagerly-computed
  optional properties left to make lazy. **Action:** close as obsolete, or downscope to the real
  residual smell — the `#warning("TODO: …trivia faff")` at `IfConfig.swift:39`, which overlaps #24.

## External / upstream (keep open, annotate)

- **#97 — Xcode 26.4 regression.** Tracks `swiftlang/swift-testing#1643`. Labelled `external issue`.
  The repo's own matrix runs 26.4 green, so nothing to build here; keep open only as a user-facing
  status pointer and close when upstream ships.
- **#40 — `@Suite` no longer needed to show test diamonds.** Tracks `FB17207500` (Apple Feedback).
  Labelled `known issue / external`. Keep open pending Apple; no code action.

---

## Diagnostics cluster (maintainer priority)

The legacy `@SnapshotSuite`/`@SnapshotTest` macros in `Sources/SnapshotsMacros`. The audit already
closed the *silent-broken-codegen* class of bugs (`1f9ef19`); what remains is mostly **fix-it
polish** — turning correct-but-terse diagnostics into guided fixes. Cross-linked: **#8, #9, #10,
#11, #21, #24, #25** open · **#12, #23** done.

- **#8 — error + fix-it for `@SnapshotTest` outside a `@SnapshotSuite`.** *(PARTIAL — high value, S)*
  A diagnostic now **exists**: `SnapshotTest.swift:83-95` (added `1f9ef19`) emits *"'@SnapshotTest'
  has no effect without an enclosing '@SnapshotSuite' type; no snapshot test will be generated."* and
  returns `nil`. Two gaps remain against the issue's literal ask ("fixit **and error**"):
  (1) it is a **warning** (`generalMessage` → `DiagnosticWarningMessage`), not an error;
  (2) there is **no fix-it**. *Decision:* warning is arguably correct — the function still compiles,
  it just produces no test — so escalating to an error would break in-progress migrations, matching
  the same reasoning used for the return-type warn-and-skip (`SnapshotTest.swift:108-115`). *Sketch:*
  make it an error if ADR #7 confirms the explicit opt-in model (recommended: an explicit test marker
  that produces no test is a correctness failure), but preserve the warning if staged migration
  leniency is an intentional product rule. Either way attach two fix-its — "Add `@SnapshotSuite` to
  the enclosing type" and "Remove `@SnapshotTest`" — mirroring the removal fix-it already built in
  `Diagnostics.swift:124-128`. **This is the highest-value diagnostics item and only S once the
  ADR-gated severity decision is made.**

- **#9 — fix-it: invalid `configurations:` → suggest `configurationValues:`.** *(STILL-OPEN, S)*
  No such fix-it exists. `SnapshotTest.swift:158-172` reads `SnapshotMacroArguments` but never
  validates a mistyped/invalid `configurations:` shape against `configurationValues:`. *Sketch:* when
  `configurationsExpression` is present but its element type doesn't unify with
  `SnapshotConfiguration<…>` (e.g. a bare value array), emit a fix-it that rewrites the argument
  label `configurations:` → `configurationValues:`. Pairs naturally with #11.

- **#10 — per-return-type fix-its for invalid return types.** *(STILL-OPEN, M)*
  Today an unsupported return type is a **warn-and-skip** (`SnapshotTest.swift:102-124`, added
  `e1ce4d6`) listing the supported set as text. #10 wants *actionable* fix-its keyed to the actual
  return type (e.g. "wrap in `AnyView`", "return `some View`"). *Sketch:* branch on the parsed
  return `TypeSyntax` and offer a targeted replacement per family (SwiftUI view-shaped →
  `some View`; UIKit/AppKit → confirm the concrete host type). M because it needs a small
  return-type classifier. Best done *with* #8's fix-it work — same diagnostic surface.

- **#11 — fix-it: configurations supplied but the value isn't passed to the function params.**
  *(STILL-OPEN, S)* The **inverse** of the now-fixed #12. `SnapshotTest.swift:160-172` covers
  "params but no configs"; there is **no** check for "configs present but the function takes no
  params (or the wrong arity)". The issue notes this fix-it already exists on the suite path — "Can
  steal this from SnapshotSuite". *Sketch:* when `configurationsExpression`/`configurationValuesExpression`
  is non-nil but `parameterClause.parameters.isEmpty`, emit an error + fix-it that adds a
  `configuration:` parameter to the function signature (or removes the argument).

- **#21 — diagnose `throws(E)` typed throws on `@SnapshotTest`.** *(STILL-OPEN, S)*
  Only untyped/empty throws is supported. The one throws check —
  `FunctionSignatureSyntax+Convenience.swift:9` — tests `throwsClause?.throwsSpecifier != nil` and
  never inspects `throwsClause.type`, and the generated wrapper is hard-coded `async throws`
  (`Test.swift:11`). A user writing `throws(MyError)` therefore has the typed-throws type **silently
  dropped**. *Sketch:* add a guard in `SnapshotTest.init?` — if
  `signature.effectSpecifiers?.throwsClause?.type != nil`, diagnose *"'@SnapshotTest' supports only
  untyped 'throws'; typed throws is not supported"* with a fix-it stripping the `(E)`.

- **#24 — whitespace weirdness in the annotate-viable-functions fix-it.** *(STILL-OPEN, S)*
  The helper (renamed to `applyingSnapshotTestAnnotationsToViableFunctions`,
  `Diagnostics.swift:157-184`) inserts `@SnapshotTest` at `Diagnostics.swift:163-166` **with no
  explicit trivia** — `functionDecl.attributes.insert(.attribute(.init(stringLiteral: "@SnapshotTest")), …)`.
  This is exactly the class of bug #23 fixed for the *static* fix-it (`Test.swift:333-349`), but the
  fix was never applied here. *Sketch:* attach leading `.newline` + inherited indentation to the
  inserted attribute (and reuse the trivia-hoist pattern from #23). Cheap, and it makes the
  `missingValidTests` "add annotations" fix-it produce clean output.

- **#25 — refactor `missingValidTests()`.** *(STILL-OPEN, hygiene, M)*
  Still a single ~70-line builder (`Diagnostics.swift:59-131`) that assembles the remove-attribute
  fix-it plus five "add a function returning X" fix-its plus the annotate-viable fix-it inline. Pure
  refactor — extract the per-return-type fix-it list into a table and the appenders into helpers.
  Low user value but it's the natural place to land #10/#24 cleanly, so **do it as the opening move
  of the diagnostics batch**, not standalone.

**Recommended diagnostics sequencing:** #25 (refactor to create clean seams) → #8 (decision + fix-its)
→ #24 (trivia, trivial) → #11 + #9 (config fix-its, share a code path) → #10 (return-type classifier)
→ #21 (typed throws, independent). This orders by "unlocks the next" rather than pure value.

---

## Configurations family (#1 / #2 / #45)

The parameterised-input API. Native path: `SnapshotConfiguration` (`SnapshotConfiguration.swift`),
`SnapshotConfigurationParser` (four `parse` overloads: `[T]`, `[SnapshotConfiguration<T>]`, closures,
and a `C: Collection` overload at `SnapshotConfigurationParser.swift:45-55`), consumed by the
`configurationValues:` macro overloads (`SnapshotTestMacroDefinition.swift:297-403`).

- **#45 — allow `Strideable`/`stride()` for `configurationValues`.** *(STILL-OPEN, S, good first issue)*
  **Root cause found.** The macro + parser accept `any Collection & Sendable`, but `stride(from:to:by:)`
  and `stride(from:through:by:)` return `StrideTo`/`StrideThrough`, which conform **only to
  `Sequence`, not `Collection`** — I verified this compiles-fails:
  > `error: global function requires that 'StrideTo<Int>' conform to 'Collection'`

  So a user's `configurationValues: stride(from: 0, to: 10, by: 2)` does not type-check today.
  *Sketch:* add `S: Sequence` overloads to `SnapshotConfigurationParser` (`parse<S: Sequence>` +
  its closure form) and the matching `configurationValues:` macro overloads. `Array` and other
  `Collection`s keep resolving to the more-specialised existing overloads; only `Sequence`-only types
  (stride, `AnySequence`) newly resolve. Guard against overload ambiguity with a quick test that an
  `Array` argument still binds to the `[T]`/`Collection` overload. The issue's "maybe `Comparable`
  instead" musing is a red herring — the constraint that matters is `Sequence`, not ordering.

- **#1 — configurations builder.** *(STILL-OPEN, M)* No result-builder exists; inputs are arrays or
  closures returning arrays. *Sketch:* a `@resultBuilder SnapshotConfigurationsBuilder` that lets
  users write `configurations { config("empty", ""); config("full", "x") }` with `buildArray`/
  `buildOptional`/`buildEither` support. Value is ergonomic, not capability — assess demand before
  building. Depends on nothing; can ship independently.

- **#2 — configuration variations / combinators.** *(STILL-OPEN, M)* Wants `product`/zip-style
  combinators (Cartesian product of two value sets) **with an explosion guard**, explicitly citing
  Swift Testing's own guidance against unbounded parameterised blow-ups. *Sketch:* free functions
  `product(_:_:)` / `zip(_:_:)` returning `[SnapshotConfiguration<(A, B)>]` (the tuple path already
  exists — `SnapshotConfiguration.swift:24-38` documents tuple-2/tuple-3 unpacking), plus a
  compile-time or runtime cap that errors past N combinations. **#1 and #2 should share a design
  session** — a builder that can also express products is one coherent API rather than two.

---

## Traits & features

- **#16 — `.deleteDirectory`/delete-stale option on `.record`.** *(STILL-OPEN, high value, M)*
  `RecordSnapshotTrait` (`RecordSnapshotTrait.swift`) only carries pointfree's `Record` kind; there
  is no cleanup mode. This is real recurring pain — the whole reference-rename churn in this repo's
  own history (`df0f2ed` "drop stale manifest exclude", `baba7ce` suite-name collisions) is the
  motivating example: after a rename, stale reference files linger. *Sketch:* add a trait option that
  deletes the snapshot directory before recording, gated behind an **explicit data-loss warning
  diagnostic** (the issue asks for this by name). The danger is deleting hand-curated references, so
  the warning + opt-in ergonomics are the hard part, not the `FileManager` call. **Top-tier value.**

- **#28 — `.timeLimit` seconds helper.** *(STILL-OPEN, S)* `TimeLimitSnapshotTrait.swift` only
  conforms `Testing.TimeLimitTrait` to the snapshot trait protocols; there is **no** seconds helper
  (grep for `seconds`/`Duration` in `Traits/` is empty). Swift Testing itself only exposes
  `.minutes(_:)`. *Sketch:* a `.timeLimit(_ duration: Duration)` helper that converts to Swift
  Testing's minute granularity. *Caveat to surface:* Swift Testing enforces minute granularity
  **deliberately**; a seconds helper that silently rounds up to the next minute could mislead. Decide
  whether to round-up-with-note or to petition upstream. S either way.

- **#26 — support vanilla SwiftUI (no UIKit/AppKit host).** *(STILL-OPEN, architectural, L)*
  Confirmed accurate: every SwiftUI path funnels through `makeSnapshotHostingController`
  (`SnapshotViewGenerator+SwiftUI.swift:56-69`), which wraps the view in `UIHostingController`/
  `NSHostingController` — so a platform *with* UIKit/AppKit is mandatory. *Sketch:* an
  `ImageRenderer`-based path (iOS 16 / macOS 13+) that rasterises SwiftUI directly without a hosting
  controller. **Spike first** — `ImageRenderer` has known gaps (no `UIViewRepresentable`, limited
  environment, scale/colorspace quirks) that may make it a *secondary* strategy rather than a
  replacement. Value is real (unlocks non-UIKit contexts) but the ceiling is uncertain until spiked.

- **#64 — forced to use `.contentView` when snapshotting `UITableViewCell`.** *(NEEDS-DECISION, M)*
  The UIView path (`SnapshotViewGenerator+UIView.swift:10-26`) vends the caller's view from a
  controller's `loadView()`. A `UITableViewCell` used as a root view renders wrong because a cell's
  content lives in `contentView` and its layout assumes a table-view context — so this is **most
  likely correct UIKit behaviour, not a library bug** (the issue itself hedges: "Could be a bug in
  client code"). *Decision needed:* (a) document that cells must be snapshotted via `.contentView` or
  wrapped in a sized container (there's already a `SnapshotView+wrappingInContainerView` helper to
  point at), and/or (b) add a small convenience that laysout-and-sizes a cell before capture.
  Reproduce first to confirm it isn't a `loadView` interaction; then most likely resolves as docs +
  optional helper. Untriaged in the audit (no label).

- **#17 — marry the macro with SwiftUI `#Preview`.** *(STILL-OPEN, exploratory, high ceiling, L)*
  No bridge exists (grep for `#Preview`/`previews` in `Sources` is empty). The issue's own framing is
  the strong direction: generate the **preview from the snapshot suite** (`#Preview { MySuite.previews }`)
  rather than the reverse. *Sketch:* have `@SnapshotSuite` also synthesise a `static var previews`
  that renders each case, so one declaration feeds both Xcode previews and snapshot tests. This is the
  single most "loveable" feature — it collapses two workflows — but it's exploratory (preview macro
  constraints, per-case identity). Prototype behind a spike.

- **#20 — `@SnapshotTest` should peer-expand to the `Test` type.** *(NEEDS-DECISION, M)*
  Today `@SnapshotTest` expands to only a `makeGenerator` container enum (`SnapshotTest.swift:7-46`);
  the actual `SnapshotSuite.TestBlock.Test` wiring is emitted by the **suite** macro walking members.
  So a user who "Expand Macro"s `@SnapshotTest` in isolation sees an opaque enum, not a test — the
  confusion the issue describes. *Decision:* whether to make `@SnapshotTest` a visible peer that
  expands its own `Test` (better discoverability, but risks double-generation with the suite pass and
  a larger expansion surface). Design question, not a quick fix. Low-med value, real UX polish.

---

## Docs / ADRs (#6 / #7)

No ADRs exist yet — `fd adr` finds nothing; `docs/` holds only the audit output. Both are genuinely
open documentation debt.

- **#7 — ADR for `@SnapshotTest` opt-in vs inference.** *(STILL-OPEN, M)* The issue body is already a
  strong ADR draft: it weighs auto-marking view-returning helpers as tests (less code) against an
  explicit opt-in (matches Swift Testing's "opt-in" mental model, avoids surprising helper→test
  promotion). This is a **real, still-live design decision** that the diagnostics work (#8) touches.
  Write it as `docs/ADRs/` per the `writing-adrs` convention; a decision here should precede #8's
  final error-vs-warning choice.

- **#6 — backfill ADRs for existing decisions.** *(STILL-OPEN, L)* Broad "write up the reasoning
  behind existing ideas". The audit has already produced excellent raw material —
  `docs/audit/holistic.md`, `renderer-view-generator.md`, `traits-scoping.md`, `concurrency-runtime.md`,
  etc. — so this is largely *distillation* of audit findings into decision records, not fresh
  archaeology. L only because of breadth. Do it incrementally, one ADR per audit theme.

---

## Cross-link map

```
Configurations family ──  #1 (builder) ─┐
                          #2 (product)  ├─ one design session; tuple path exists (SnapshotConfiguration.swift:24-38)
                          #45 (stride) ─┘   #45 ships independently (S); #1+#2 co-designed (M)

Diagnostics cluster ──   #25 refactor ─→ opens seams for ↓
                         #8  no-suite (warning exists; +fix-its)      \
                         #9  invalid configurations: label            }─ share the SnapshotTest diagnostic surface
                         #10 return-type fix-its                      }   (SnapshotTest.swift / Diagnostics.swift)
                         #11 configs-without-params (inverse of #12)  /
                         #24 annotate-fix-it trivia (same bug as #23, unfixed here)
                         #21 typed throws (independent)
                         #12 DONE (1f9ef19) · #23 DONE (1a3323d)

Docs pair ──             #7 (@SnapshotTest ADR) ─→ should precede #8's error-vs-warning decision
                         #6 (backfill) ─→ distils docs/audit/*.md

Rendering ──             #18 DONE (94d11b6+) · #26 (SwiftUI-only) · #64 (UITableViewCell) — all hosting-layer
Preview ──               #17 (exploratory, highest ceiling) ─ relates to #20 (expansion visibility)
```

---

## Top candidates to build next (ranked)

1. **#8 — `@SnapshotTest`-outside-suite fix-its** *(high value, S).* The diagnostic already exists;
   this is a warning-vs-error decision plus two fix-its reusing `Diagnostics.swift:124-128`.
   Recommendation: error under the explicit opt-in model, warning only if migration leniency is a
   deliberate rule. Best value/effort ratio on the board. Gate the decision on **#7**.
2. **#16 — `.record` stale-reference cleanup + data-loss warning** *(high value, M).* Recurring real
   pain (this repo's own rename churn is the case study); the issue even specifies the safety
   diagnostic. The hard part is the guardrails, not the delete.
3. **#45 + #28 — two S-sized wins** *(med value, S each).* `stride()` support (root cause pinned:
   add `Sequence` overloads) and the `Duration` seconds helper. Both "good first issue"-shaped, ship
   in a day.
4. **#25 → #24 → #11/#9 → #10 diagnostics batch** *(med value, M total).* Sequenced so the refactor
   creates clean seams and each fix-it reuses the last. Delivers the maintainer-priority "surface
   failures to users" theme as one coherent PR.
5. **#17 — `#Preview ↔ suite` bridge** *(high ceiling, L, spike first).* The single most differentiating
   feature; prototype behind a throwaway spike before committing.

**Immediate housekeeping (no build):** close **#23, #12, #18, #13, #14** with the evidence above, and
resolve **#22** as an obsolete premise. That clears 6 of 26 issues and focuses the board on the ~10
that actually need work.
