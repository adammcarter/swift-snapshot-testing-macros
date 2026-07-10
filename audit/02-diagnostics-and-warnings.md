# 02 — Diagnostics & warnings to surface (deep)

**Priority lane.** The maintainer's stated priority is *"warnings/failures to surface to
users."* Every open issue on the `diagnostics` label (#8, #9, #10, #11, #12, #21, #24, #25)
is in scope, plus the runtime failure surface. This doc is the deep version: it first
re-establishes the **current** truth (the lighter baseline was written against an earlier
state and is now wrong in several places), then gives a complete inventory of what is
diagnosed vs. silently-wrong/cryptic today with `file:line`, then an implementable catalogue
of new diagnostics.

The library has **two macro modules** and one runtime module:

| Module | Role | Diagnoses from |
|---|---|---|
| `SnapshotsMacros` | legacy `@SnapshotSuite`/`@SnapshotTest` peer+member expansion, and the `#expectSnapshot` **expansion** | `MacroExpansionContext.diagnose` at compile time |
| `SnapshotTestingMacros` | runtime: `__expectSnapshot` adapter, asserters, renderers, traits | `Issue.record` / `XCTFail` at run time |
| `SnapshotMigrationSupport` + `SnapshotMigrationCLI` | migration tool | `ConsoleReporter`/`JSONReporter` (out of scope here) |

---

## 0. Baseline corrections (read this first)

The prior doc is stale on six points. The deep audit must not repeat them:

| Claim in lighter baseline | Actual current state | Evidence |
|---|---|---|
| #8 `@SnapshotTest` outside a suite is "peer returns `nil` silently, no message" | **Already diagnosed** — but as a **warning with no fix-it**. Issue #8 wants **error + fix-it**. | `SnapshotTest.swift:83-95` (`generalMessage` = warning severity) |
| #12 args-without-configurations gives "cryptic compile error in expansion" | **Already a hard error** with an actionable message — but **no fix-it**. | `SnapshotTest.swift:160-172` (peer), `Test.swift:168-173` (suite path returns nil to avoid dup) |
| Per-case discriminator collision routes around the guard (an open bug) | **Closed.** Commit `7460647` wired the folded discriminator through the collision check. | `ExpectSnapshotAdapter.swift:1117-1142`, `SnapshotExecutionContext.swift:146` |
| #23 trivia bug "now fixed in `c45f3a9`" | Code path is carefully handled, **but issue #23 is still OPEN** on the tracker, and its sibling **#24 is a live, unfixed bug** (below). | `Test.swift:326-349` (careful) vs `Diagnostics.swift:163-166` (broken) |
| The process-aborting `preconditionFailure` "is now a recorded issue" | Two invariant guards remain in the AppKit result-box workaround, but both boxes are assigned synchronously and unconditionally. They are internal hardening opportunities, **not a demonstrated user-reachable crash**. | `StrategyAssertionRequestGenerator.swift:94-108, 133-148` |
| inout/variadic + interpolated display name still "silently mishandled" | **Already hard errors.** | `SnapshotTest.swift:126-135, 147-156`; `canContinueAfterSanityChecks.swift:37-48` |

**Net:** the remaining diagnostic work is less "silent → loud" (much of that shipped) and
more **severity/fix-it upgrades** (#8, #12), **genuinely-missing diagnostics** (#9, #11, #21,
`#expectSnapshot` dropped-argument), one **real trivia bug** (#24), one **refactor** (#25),
and **runtime message quality** (timeout and size errors), plus one internal AppKit box cleanup.

---

## 1. Complete inventory — what fires today

### 1a. Compile-time diagnostics that exist

| # | Trigger | Severity | Fix-it? | `file:line` |
|---|---|---|---|---|
| C1 | `@SnapshotSuite` on an `extension` | error | no | `canContinueAfterSanityChecks.swift:21-32` |
| C2 | `@SnapshotSuite` display name is interpolated / non-literal | error | no | `canContinueAfterSanityChecks.swift:37-48` |
| C3 | `@SnapshotSuite` present but no `@Suite` attribute | warning | **yes** (insert `@Suite`) | `canContinueAfterSanityChecks.swift:52-93`, `Diagnostics.swift:30-57` |
| C4 | `@SnapshotSuite` with no viable tests | warning | **yes** (5 fix-its: stub View/UIView/UIViewController/NSView/NSViewController + annotate-viable + remove-attr) | `Diagnostics.swift:59-131` |
| C5 | instance `@SnapshotTest` func on a non-initialisable type | error | **yes** (make `static`) | `Test.swift:96-105, 320-364` |
| C6 | non-`async` func on suite with `async` init | error | **yes** (make `async`) | `Test.swift:117-133, 366-389` |
| C7 | non-`throws` func on suite with `throws` init | error | **yes** (make `throws`) | `Test.swift:122-149, 391-414` |
| C8 | two `@SnapshotTest` funcs resolve to the same display name | warning (per func) | no | `Test.swift:270-297` |
| C9 | `@SnapshotTest` on a non-function decl | error | no | `SnapshotTest.swift:65-76` |
| C10 | `@SnapshotTest` with **no enclosing `@SnapshotSuite`** | **warning** | **no** | `SnapshotTest.swift:83-95` |
| C11 | `@SnapshotTest` unsupported return type | **warning (warn-and-skip)** | no | `SnapshotTest.swift:102-124` |
| C12 | `@SnapshotTest` interpolated display name | error | no | `SnapshotTest.swift:126-135` |
| C13 | `@SnapshotTest` `inout`/variadic params | error | no | `SnapshotTest.swift:147-156`, `FunctionSignatureSyntax+Convenience.swift:23-28` |
| C14 | parameterised `@SnapshotTest` with no `configurations:`/`configurationValues:` | **error** | **no** | `SnapshotTest.swift:160-172` |
| C15 | `#expectSnapshot` with no value and no closure | error (expands to `()`) | no | `ExpectSnapshotMacro.swift:42-51` |

### 1b. Runtime diagnostics that exist

| # | Trigger | Surfaced as | `file:line` |
|---|---|---|---|
| R1 | `#expectSnapshot` off the active test task (detached/GCD/XCTest host) | recorded issue, assertion skipped (no longer `preconditionFailure`) | `SnapshotRuntimePreconditions.swift:16-41` |
| R2 | snapshot mismatch / missing reference | recorded issue via pointfree, attributed across the main-actor hop | `Asserter.swift:106-123`, `SnapshotFailure.swift:31-57` |
| R3 | `argument:`/config derived-name collision across cases | recorded issue + skip | `ExpectSnapshotAdapter.swift:750-797` |
| R4 | **per-case** unnamed-assertion derived-name collision | `SnapshotFailure` carried back + recorded + skip | `ExpectSnapshotAdapter.swift:1117-1142` |
| R5 | zero / zero-width / zero-height render size | `throw SizeError` → recorded | `SizeAssertionRequestGenerator.swift:50-119` |
| R6 | non-positive/non-finite `.fixed` length or scale | `throw SizeError.invalid*` → recorded | `SizeAssertionRequestGenerator.swift:148-160` |
| R7 | unrenderable AppKit bitmap (huge-but-finite size) | pre-flight `throw SnapshotError` (no longer `fatalError`) | `StrategyAssertionRequestGenerator.swift:52-54`, `AppKitImageRenderer.swift:164-207` |
| R8 | non-throwing pipeline errors on non-throwing overloads | recorded issue, nothing escapes | `ExpectSnapshotAdapter.swift:824-856, 911-943` |

### 1c. What is still silently wrong, dropped, or cryptic

| Key | Today's behaviour | `file:line` | Issue |
|---|---|---|---|
| **S1** | `@SnapshotTest` outside a suite: **warning only, no fix-it** — user marks a func, gets a yellow squiggle, and no test is generated. The single worst UX still isn't an error. | `SnapshotTest.swift:87-94` | #8 |
| **S2** | `throws(SomeError)` typed throws: `isThrows` checks only that a `throwsSpecifier` exists, so a typed throw is treated as untyped `throws`, the **error type is dropped** from the generated wrapper, and nothing warns. | `FunctionSignatureSyntax+Convenience.swift:8-10`; `Test.swift:9-16` | #21 |
| **S3** | `configurations:` given bare values (not `SnapshotConfiguration`), or a shape the overloads can't match: fails to resolve an overload / type-errors in generated code with **no hint to switch to `configurationValues:`**. | macro overloads `SnapshotTestMacroDefinition.swift:146-405`; no diagnostic anywhere | #9 |
| **S4** | `configurations:` supplied but the value is **never forwarded** to the function parameter (func takes no matching arg): the generated `makeGenerator` mismatches. No dedicated diagnostic — the SnapshotSuite path had one to "steal". | `Test.swift`/`SnapshotTest.swift` (no forwarding check) | #11 |
| **S5** | parameterised-args error (#12) **has no fix-it** — the message tells the user what's wrong but doesn't insert `configurations:`/`configurationValues:` for them. | `SnapshotTest.swift:160-172` | #12 |
| **S6** | unsupported return type is **warn-and-skip with a generic message** — no per-return-type fix-it (e.g. "wrap in `AnyView`", "return `some View`"). | `SnapshotTest.swift:116-123` | #10 |
| **S7** | `applyingSnapshotTestAnnotationsToViableFunctions()` (the fix-it behind #24, formerly `makeNewNodeWithSnapshotTestAnnotationsOnViableFunctions`) inserts `@SnapshotTest` **with no leading/trailing trivia management** — unlike the careful handling in `addNonInstantiableFunctionDiagnostic`. Applying the fix-it can fuse `@SnapshotTestfunc` or mangle indentation. | `Diagnostics.swift:157-184` (esp. 163-166) | #24 |
| **S8** | `#expectSnapshot(a, b)` with **two unlabeled non-closure values**: the second is silently dropped (`makeValueArguments.first` only). No diagnostic. | `ExpectSnapshotMacro.swift:25-41` | new |
| **S10** | hardcoded `timeout: 5` — no way to configure; a slow async render fails with pointfree's generic timeout message that never mentions a trait. | `Asserter.swift:104-117` (`#warning`) | new / #(timeout) |
| **S11** | `SizeError` messages ("Zero width for snapshot") never name **which** size trait / permutation produced them, so a fan-out failure is hard to localise. | `SizeAssertionRequestGenerator.swift:60-73` | new |
| **S12** | `missingValidTests()` is one 70-line factory that builds 7 fix-its inline — the least testable diagnostic, blocking confident future work. | `Diagnostics.swift:59-131` | #25 |

---

## 2. New-diagnostic catalogue (implementable)

Each entry: the precise user mistake → the trigger condition (with `file:line` to change) →
severity → exact message → fix-it sketch → effort.

### P1 — silent/weak → loud, small, high value

#### N1 · #8 — `@SnapshotTest` outside `@SnapshotSuite`: decide severity + add fix-its  (S)
- **Mistake:** user annotates a function with `@SnapshotTest` in a type (or file scope) that
  has no `@SnapshotSuite`; nothing runs.
- **Trigger:** `SnapshotTest.swift:83-95` — the `guard … enclosingDecl … snapshotSuite …`
  branch. Attach fix-its that add `@SnapshotSuite` to the enclosing type or remove the inert
  `@SnapshotTest` (reuse the `missingAttribute` insertion pattern in `Diagnostics.swift:30-57`).
- **Severity:** gate on ADR #7. **Recommendation: error** if `@SnapshotTest` remains an explicit
  opt-in marker, because an explicit test that produces no test is a correctness failure. Keep the
  warning only if staged-migration leniency is recorded as an intentional product rule.
- **Message:**
  `'@SnapshotTest' has no effect without an enclosing '@SnapshotSuite'; no snapshot test will be generated.`
- **Fix-it:** *"Add @SnapshotSuite to '<TypeName>'"* — insert `@SnapshotSuite\n` at
  `enclosingDecl.attributes.startIndex` (with a leading newline, mirroring `missingAttribute`).
  When there is no enclosing type at all (file-scope function), offer instead *"Wrap in an
  @SnapshotSuite type"* or omit the fix-it and keep the error.
- **Watch:** the peer macro can't always see the enclosing decl as a mutable node (lexical
  context members are stripped); the fix-it target must be the enclosing decl from
  `context.lexicalContext.first`, and trivia must be handled (see N7).

#### N2 · #21 — typed `throws(Type)` rejection + fix-it  (S)
- **Mistake:** `@SnapshotTest func foo() throws(MyError) -> some View`.
- **Trigger:** add a check in `SnapshotTest.swift` init (alongside the other signature guards,
  ~`:147`) and in `Test.swift` init: inspect
  `signature.effectSpecifiers?.throwsClause?.type != nil`. Today `FunctionSignatureSyntax.isThrows`
  (`:8-10`) ignores the type entirely.
- **Severity:** **error + fix-it** (maintainer: "We only support empty throws / no throws").
- **Message:**
  `'@SnapshotTest' supports untyped 'throws' only; typed throws ('throws(MyError)') is not supported.`
- **Fix-it:** *"Use untyped 'throws'"* — replace the `ThrowsClauseSyntax` with a bare
  `throws` (drop `.type` and its parens), preserving surrounding trivia.
- **Note:** also audit the suite-init path — a suite whose `init() throws(E)` currently reads
  as untyped throws in `Declaration.isThrows`; same rejection should apply so the generated
  `try` wrapper stays sound.

#### N3 · #9 — invalid `configurations:` → suggest `configurationValues:`  (S/M)
- **Mistake:** `@SnapshotTest(configurations: ["Alice", "Bob"])` — bare values passed to the
  `configurations:` label, which expects `[SnapshotConfiguration<T>]`.
- **Trigger:** in `SnapshotTest.swift`/`Test.swift` after `SnapshotMacroArguments`
  (`SnapshotMacroArguments.swift:10-11`), detect a `configurations:` argument whose expression
  is an array literal whose elements are **not** `SnapshotConfiguration(...)`/`FunctionCallExpr`
  producing one (best-effort syntactic check — the macro can't type-check, but bare string/
  int/identifier literals are a strong signal). This is a heuristic diagnostic, so keep it a
  **warning** to avoid false positives on `let cfgs` references.
- **Severity:** **warning + fix-it** (rename the label).
- **Message:**
  `'configurations:' expects [SnapshotConfiguration<T>]; these look like raw values. Use 'configurationValues:' to pass values directly.`
- **Fix-it:** *"Replace 'configurations:' with 'configurationValues:'"* — rewrite the
  `LabeledExprSyntax.label` token from `configurations` to `configurationValues`. (The parser
  and overloads already accept `configurationValues:` collections —
  `SnapshotConfigurationParser.swift:26-54`, `SnapshotTestMacroDefinition.swift:363-405`.)
- **Effort:** S if limited to array-literal-of-literals; M if it also recognises
  `SnapshotConfiguration` element detection robustly.

#### N4 · #11 — `configurations:` supplied but value not forwarded to the parameter  (S/M)
- **Mistake:** `configurations:`/`configurationValues:` provided, but the function's parameter
  list doesn't consume the configuration value (e.g. `func foo() -> some View` with
  `configurations: [...]`, or a param whose type can't receive the config value).
- **Trigger:** `SnapshotTest.swift:160-172` currently only checks *params-without-config*.
  Add the **inverse**: `parameterClause.parameters.isEmpty && (configurationsExpression != nil || configurationValuesExpression != nil)`.
  The maintainer note says "Can steal this from SnapshotSuite" — port whatever forwarding
  check the suite path uses.
- **Severity:** **error + fix-it**.
- **Message:**
  `'@SnapshotTest' was given 'configurations:' but 'func foo()' takes no parameter to receive the value.`
- **Fix-it:** *"Add a parameter for the configuration value"* — insert a
  `<#value#>: <#Type#>` parameter into the signature (best-effort; the type is unknown at
  expansion, so use a placeholder), or *"Remove 'configurations:'"* as the safe alternative.

#### N5 · #12 — parameterised-args error: add the missing fix-it  (S)
- **Mistake:** `@SnapshotTest func foo(state: State) -> some View` with no `configurations:`.
- **Trigger:** the error already fires at `SnapshotTest.swift:160-172`. Only the fix-it is
  missing.
- **Severity:** already **error**; add **fix-it**.
- **Message (keep):**
  `A parameterised '@SnapshotTest' function requires a 'configurations:' or 'configurationValues:' argument.`
- **Fix-it:** *"Add 'configurationValues:'"* — insert `configurationValues: [<#values#>]` as
  the last labeled argument of the `@SnapshotTest(...)` attribute (build the
  `LabeledExprSyntax` and append to `node.arguments`). Offer a second *"Add 'configurations:'"*
  variant inserting `[SnapshotConfiguration(name: <#name#>, value: <#value#>)]`.

### P2 — structural

#### N6 · #10 — per-return-type fix-its for unsupported return types  (M)
- **Mistake:** `@SnapshotTest func foo() -> Text` / `-> AnyView` / `-> MyView` / `-> Void`.
- **Trigger:** `SnapshotTest.swift:102-124` (the warn-and-skip). Keep the warn-and-skip
  (deliberately lenient so in-progress migrations build — see the rationale comment at
  `:108-115`), but **branch the message + fix-it per detected return shape** using
  `Constants.Configuration.supportedReturnTypes` (`some View`, `UIView`, `UIViewController`,
  `NSView`, `NSViewController`).
- **Severity:** **warning + fix-it** (per type).
- **Messages / fix-its:**
  | Detected return | Message add-on | Fix-it |
  |---|---|---|
  | `Void` / none | "no view is returned" | *"Return a SwiftUI view"* → append `-> some View` + `<#return#>` body stub |
  | concrete `View` (`Text`, `AnyView`, `some SwiftUI.View`, typealias) | "concrete/aliased view types aren't recognised" | *"Change return type to 'some View'"* → rewrite `returnClause.type` to `some View` |
  | a `UIView`/`NSView` subclass spelled with a module prefix | "only the bare type name is recognised" | *"Use 'UIView'"* etc. |
- **Note:** because a view-shaped concrete type can't be told from a genuinely unsupported one
  at expansion, the fix-its are *suggestions*, and the diagnostic must stay a warning.

#### N7 · #24 — trivia bug in the annotate-viable-functions fix-it  (S, real bug)
- **Mistake:** user applies the *"Add @SnapshotTest annotations to viable functions"* fix-it
  from the missing-tests diagnostic (C4).
- **Trigger:** `Diagnostics.swift:163-166` inserts
  `.attribute(.init(stringLiteral: "@\(…snapshotTest)"))` at `attributes.startIndex` with **no
  trivia**. Compare the correct handling in
  `Test.swift:326-349` (which explicitly moves leading trivia onto the inserted node and leaves
  a space behind). Port that pattern: give the inserted attribute `.leadingTrivia` matching the
  function's existing indentation and a `.newline`/`.space` trailing, and rebalance the first
  token's leading trivia so `@SnapshotTest` doesn't fuse onto `func`/a modifier.
- **Severity:** bug fix (no new diagnostic).
- **Verification:** add golden expansion fixtures for: annotate a func with no modifiers, one
  with `public`/`static`, one already indented inside a nested type, one with an existing
  attribute. Do the same audit for **every** `DeclModifierSyntax`/`AttributeSyntax` insertion
  (C3, C4 stubs, C5-C7) — issue #23 is still open, so the whole insertion surface needs
  golden coverage, not just this one call.

#### N8 · #25 — refactor `missingValidTests()`  (M, unblocks the rest)
- **Trigger:** `Diagnostics.swift:59-131` builds 7 fix-its inline in one factory with two
  private `DeclGroupSyntax` extensions doing string-templated decl construction.
- **Plan:** split into one small builder per fix-it (`AddViewStubFixIt`,
  `AnnotateViableFixIt`, `RemoveAttributeFixIt`, …), each independently unit-testable against a
  golden expansion; have `missingValidTests` compose them. This is the enabling refactor —
  N1/N2/N4/N5/N6/N7 all add or touch fix-its, and today there's no seam to test them in
  isolation.

#### N9 · #expectSnapshot dropped-argument diagnostic  (S)
- **Mistake:** `#expectSnapshot(valueA, valueB)` (two unlabeled non-closure values) — B is
  silently ignored.
- **Trigger:** `ExpectSnapshotMacro.swift:25-41`. After computing `value` and
  `makeValueExpression`, if `makeValueArguments.dropFirst()` (or the residue after the builder
  is chosen) still contains unlabeled expressions, diagnose.
- **Severity:** **error** (returns `()` like C15, or keeps the first and errors).
- **Message:**
  `#expectSnapshot takes a single value or a value builder; extra unlabeled argument(s) were ignored.`
- **Fix-it:** none needed (remove-arg is ambiguous); the error is the value.

### P3 — runtime message quality

#### N10 · Configurable timeout + trait-named timeout message  (S/M) — `Asserter.swift:104`
- Expose a `.snapshotTimeout(_:)` `SnapshotTestTrait`/`SnapshotSuiteTrait` (avoiding ambiguity with
  Swift Testing's own time-limit surface, and mirroring the existing
  `TimeLimitSnapshotTrait` in `Traits/AppleSwiftTesting/`), thread it into
  `PointfreeAsserter.verifySnapshot` in place of the hardcoded `timeout: 5`, and default to 5.
- On timeout, wrap pointfree's message so it names the trait:
  `Snapshot timed out after <n>s. Increase it with '.snapshotTimeout(.seconds(<n>))' on the test or suite.`
- Removes the `#warning("TODO: Allow timeout customisation via new trait")`.

#### H1 · Centralize the synchronous AppKit result-box workaround  (S) — `StrategyAssertionRequestGenerator.swift:94-160`
- Both `MainActorResultBox` instances are assigned synchronously and unconditionally inside
  `MainActor.assumeIsolated`; no user-controlled nil path was found. The two
  `preconditionFailure`s are therefore invariant guards, not missing runtime diagnostics.
- Extract one `withSynchronousMainActorResult` helper that owns the unchecked-sendable invariant and
  its single guard. Re-probe whether newer `assumeIsolated` result transfer removes the helper only
  after Swift 6.1 support is dropped. This reduces duplicated unsafe ceremony without pretending the
  non-throwing `Snapshotting.pullback` transform can record a normal test failure.

#### N12 · Name the size permutation in `SizeError`  (S) — `SizeAssertionRequestGenerator.swift:60-73`
- Include the offending `traitSize` (`.debugDescription` from `SizesSnapshotTrait.Length`) and
  the resolved absolute size in the message:
  `Zero width for snapshot at size '.fixed(0) × .minimum' (resolved 0×44). Set a positive width via '.sizes(.fixed(…))'.`
- Purely message enrichment; the throw sites (`:98-108`) already have `absoluteSize` and the
  `traitSize` in scope.

#### N13 · Richer missing-vs-mismatch failure comment  (S) — `Asserter.swift:120-122`, `SnapshotFailure.swift`
- pointfree's message distinguishes "no reference recorded" from "reference did not match".
  When it's a missing reference, append the record hint:
  `No reference recorded. Re-run with the '.record(.all)' trait or SNAPSHOT_TESTING_RECORD=all to record it.`
- Keep the mismatch message as-is but ensure the artifact path is surfaced (pointfree already
  includes it; verify it survives the `SnapshotError(message:)` round-trip at `Asserter.swift:121`).

---

## 3. Roadmap (order of attack)

```
P1  N1 #8   ADR-gated severity + two no-op-test fix-its   S   ── biggest UX win
    N2 #21  typed-throws rejection + untyped fix-it        S
    N5 #12  add the missing fix-it (error already fires)   S
    N3 #9   configurations→configurationValues fix-it      S/M (heuristic, warn)
    N4 #11  config-not-forwarded error + fix-it            S/M (port from suite)
      │
P2  N8 #25  refactor missingValidTests → per-fix-it units  M   ── unblocks fix-it testing
    N7 #24  trivia fix in annotate-viable fix-it + goldens S   (do with/after N8)
    N6 #10  per-return-type fix-its (keep warn-and-skip)   M
    N9      #expectSnapshot dropped-argument error         S
      │
P3  H1      centralize the AppKit result-box invariant     S   ── unsafe-boundary hardening
    N10     configurable .timeout trait + named message    S/M
    N12     name the size permutation in SizeError         S
    N13     missing-vs-mismatch record hint                S
```

**Rationale for the order:** N1/N2/N5 are pure severity/fix-it upgrades on code that already
diagnoses — smallest change, largest UX delta, and they're the maintainer's headline issues.
N8 (#25) is sequenced before the fix-it-heavy P2 items because it creates the only seam where
new fix-its (N6, N7, and the N1/N5 additions) can be golden-tested in isolation. N7 (#24) is a
*live bug*, not an enhancement — but it lives inside the `missingValidTests` factory, so doing
N8 first avoids touching that code twice. P3 hardens the remaining AppKit unchecked boundary and
closes the runtime message-quality gaps.

## 4. Principle

Every place the library can produce a **broken, empty, dropped, or overwritten** artifact from
a plausible user mistake must emit a diagnostic — and where the fix is mechanical, a **fix-it**,
not just a message. The crash-removal and silent-collision work has largely shipped (R1–R8,
C1–C15); what remains is (a) upgrading two already-detected mistakes from weak to loud
(#8 ADR-gated severity plus fix-its, #12 error→error+fix-it), (b) the four genuinely-missing diagnostics
(#9, #11, #21, dropped-arg), (c) one real trivia bug (#24) behind a refactor (#25), and
(d) runtime message quality (timeout and size/record hints), plus AppKit unsafe-boundary cleanup. A silent wrong
that passes CI is worse than a crash; a cryptic error in generated code is worse than a fix-it.
