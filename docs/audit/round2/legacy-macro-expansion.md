# Audit round 2: legacy-macro-expansion

Primary verification target: the async codegen fix (round-1 finding 1) is solid — the runtime `SnapshotViewGenerator` has async `makeValue` overloads on all three shapes (base/SwiftUI/UIView), stores them as `makeViewControllerAsync`, and `assertSnapshot(with:)` -> `resolvedSyncViewGenerator` awaits exactly once before rebuilding a synchronous generator; the peer emits `await Suite().fn()` which correctly covers the async-init+async-function case. All 8 hardened diagnostics fire and are fixture-covered (parameterised-without-config, `@available`-to-container, `Collection` parser overloads, nil/interpolated display names, unsupported return type, non-function attachment, bare `@SnapshotTest`, non-instantiable + extension). The `Test.swift:117` static carve-out for the async-init diagnostic is correct. However, the hardening introduced/left defects. Most serious NEW issues: (1) the finding-10 instantiability rewrite regressed — it inspects only the first initializer, so a valid suite with a required-arg init declared before a zero-arg init (which compiled and worked before commit 1f9ef19) now hits a false-positive "cannot be initialised" hard error; (2) the async-init hardening has no throwing-init analogue — an `init() throws` suite with a non-throwing function emits `Suite().fn()` with no `try`, an undiagnosed compile error, and the async fix-it is insufficient for `init() async throws`; (3) the "Make function static" fix-it emits malformed `@SnapshotTeststatic` (unknown-attribute error), a broken fix-it whose broken output is even baked into committed fixtures. Plus a low return-type over-rejection (some `SwiftUI.View`/`AnyView`/`Text` now hard-error where they previously compiled). Round-1 findings 11, 12, 13, 14 are confirmed still open (unchanged code paths); 12 and 11 remain needs_dynamic_verification. Two improvement/coverage items noted (async-init guard missing `return nil`; explicit-same-display-name collisions uncovered). No tracked files were modified; no builds were run except the pre-push gate below.

## Findings

### 1. Instantiability fix (finding 10) regressed: valid multi-initializer suites now hard-error because only the FIRST initializer is inspected
- Severity: medium
- File: Sources/SnapshotsMacros/SnapshotSuite/_Support/Declaration.swift:104
- Failure scenario: `@SnapshotSuite struct S { init(dep: Dep) {}; init() {}; @SnapshotTest func makeView() -> some View { Text("x") } }`. `initializer(in:)` (Declaration.swift:104-112) returns only the FIRST `InitializerDeclSyntax` in member order (`.lazy.compactMap{...}.first`) — here `init(dep:)`. `isCallableWithoutArguments` (Declaration.swift:45-53) sees a non-defaulted param -> `false` -> `makeIsInitializable` (Declaration.swift:37-42) -> `false` -> `Test.swift:96-105` emits the hard error "Cannot create a test for instance functions on types that cannot be initialised." and generates nothing. Yet `S()` compiles fine against `init()`. Pre-1f9ef19, `makeIsInitializable` was just `is(Struct/Class/Actor)`, so this exact suite compiled and generated a working test before.
- Evidence: `git show 1f9ef19~1:.../Declaration.swift` confirms the prior unconditional-true behavior. No fixture covers multiple initializers (`LegacyHardening.requiredParameterInitIsRejected` uses a single `init(value:)` only). Same first-init bias also mis-derives `isAsync`/`isThrows` for multi-init suites (Declaration.swift:96-101).
- Suggested fix: consider ALL initializers, not just the first — `isInitializable` should be true if ANY explicit init is callable with zero arguments (or, with no explicit init, the implicit/memberwise init is). Replace the single `initializer(in:)` lookup with a scan over all `InitializerDeclSyntax` members.
- needs_dynamic_verification: false

### 2. Async-init hardening (finding 1) has no throwing-init analogue: throwing suite init + non-throwing function emits `Suite().fn()` with no `try` and no diagnostic
- Severity: medium
- File: Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:117
- Failure scenario: commit baba7ce diagnoses the async-init + non-async-function shape (Test.swift:117-125, guarded by `suiteDeclaration.isAsync`) but has no equivalent check for `suiteDeclaration.isThrows`. A suite with `init() throws {}` passes `isInitializable` (`isCallableWithoutArguments` does not inspect `throws`), so a test is generated and the peer emits `makeValue: { Suite().makeView() }` with no `try`. `Suite()` calls a throwing initializer, so generated code fails to compile with "call can throw but is not marked with try" — cryptic and undiagnosed. Additionally, for `init() async throws` the async fix-it "Make function async" only adds `async`, leaving the generated `await Suite().makeView()` still missing `try` — the fix-it output still does not compile.
- Evidence: `Test.swift:117` checks only `suiteDeclaration.isAsync`; grep shows no `suiteDeclaration.isThrows` consumer on the suite side. `SnapshotViewGenerator.swift:52` derives `isThrows` from the FUNCTION's declaration only (`macroContext.declaration` is the function per `SnapshotTest.swift:177`), so it's always false for the init. `isCallableWithoutArguments` (Declaration.swift:45-53) accepts `init() throws`. Fixture gap: `SnapshotSuiteTests+FunctionModifiers+Throws.swift` covers throwing FUNCTIONS and a non-throwing init only; no `init()...throws` fixture found repo-wide.
- Suggested fix: mirror the async-init diagnostic for `suiteDeclaration.isThrows` (reject/fix-it non-static, non-throwing functions under a throwing suite init), and make the async-init fix-it add `throws` too when the init also throws (or emit `try await` in the peer for async-throws inits).
- needs_dynamic_verification: false

### 3. "Make function static" fix-it produces malformed `@SnapshotTeststatic` (unknown-attribute error) — applying it makes the build worse
- Severity: medium
- File: Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:247
- Failure scenario: `addNonInstantiableFunctionDiagnostic` inserts a `static` modifier via `DeclModifierSyntax(name: .keyword(.static))` with NO leading/trailing trivia (Test.swift:243-250). Because the newline+indent between `@SnapshotTest` and `func` lives on the `funcKeyword`'s leading trivia, the trivia-less `static` lands directly against the attribute, rendering `@SnapshotTeststatic\n  func`. That parses as a single unknown attribute `@SnapshotTeststatic` (a new compile error), and the function is NOT actually made static — applying the fix-it in Xcode replaces one error with another and drops the test entirely.
- Evidence: contrast the async fix-it at Test.swift:276, which correctly uses `.keyword(.async, trailingTrivia: .space)`. Recorded broken output: `SnapshotTestTests+LegacyHardening.swift` `fixes:` blocks show `@SnapshotTeststatic` at lines 398, 415, 480, 493, 578, 678, and the following `expansion:` block (LegacyHardening.swift:420-425) shows an EMPTY generated suite because `hasAttributeNamed("SnapshotTest")` (`AttributeListSyntax+Convenience.swift:26-34`, exact-match) no longer matches `@SnapshotTeststatic`. These broken fixtures are currently committed as "expected".
- Suggested fix: give the inserted `static` modifier the `funcKeyword`'s leading trivia plus a trailing space, and reset the `funcKeyword`'s leading trivia to a single space; re-record the affected fixtures.
- needs_dynamic_verification: false

### 4. Return-type hardening (finding 7) hard-errors legitimate SwiftUI view spellings that previously compiled (some SwiftUI.View, AnyView, Text, typealiases)
- Severity: low
- File: Sources/SnapshotsMacros/Support/Constants/Constants+Configuration+supportedReturnTypes.swift:5
- Failure scenario: `hasSupportedReturnType` is an exact trimmed-string membership test against `{"some View","UIView","UIViewController","NSView","NSViewController"}` via `FunctionDeclSyntax.hasReturnType` (exact `==`). The peer turns any non-member return type into a HARD error (SnapshotTest.swift:102-116). `-> some SwiftUI.View` (module-qualified, semantically identical to `some View`), `-> AnyView`, `-> Text`, and view typealiases previously compiled as a dead-but-valid container (the SwiftUI `makeValue: (…) -> any SwiftUI.View` overload accepted them) — no test generated, but no build break either. They now hard-block compilation, converting a silent no-op into a compile break.
- Evidence: `supportedReturnTypes` exact set (Constants+Configuration+supportedReturnTypes.swift:5-13); `hasReturnType` uses `trimmedDescription ==` (`FunctionDeclSyntax+Convenience.swift:20-22`); peer hard error path `SnapshotTest.swift:102-116`; fixture `unsupportedReturnTypeIsRejected` (LegacyHardening.swift:216-255) errors on `-> Text`. `some SwiftUI.View` trims to `"some SwiftUI.View"` != `"some View"` -> rejected.
- Suggested fix: broaden detection (accept `some <...>View` / `any View` / known view-protocol suffixes and module-qualified spellings), or downgrade the unsupported-return diagnostic to a warning+skip for view-shaped opaque returns so an in-progress migration still builds.
- needs_dynamic_verification: false

### 5. [carry-over, still open — round-1 #13] Overloaded @SnapshotTest functions still emit duplicate `__generator_container_<name>` (invalid redeclaration)
- Severity: low
- File: Sources/SnapshotsMacros/Support/Constants/makeContainerName.swift:6
- Failure scenario: unchanged by either fix commit (still carries `#warning("TODO: Can we do better than this?")`). The container name is `__generator_container_` + the base function name only, so two `@SnapshotTest` overloads that differ only in parameters (e.g. `makeView()` and `makeView(x: Int)` with a configuration) both emit `enum __generator_container_makeView` in the same scope -> "invalid redeclaration".
- Evidence: `makeContainerName.swift:5-7` (unchanged); used identically by `SnapshotTest.swift:159` (peer container) and `Test.swift:148` (suite reference). `generatedIdentifierComponent` only hashes non-ASCII names (`TokenSyntax+GeneratedIdentifier.swift:37-39`), so plain ASCII overloads always collide.
- Suggested fix: incorporate a stable signature hash (parameter types) into the container name on both the peer and suite sides, or diagnose overloaded `@SnapshotTest` functions as unsupported.
- needs_dynamic_verification: false

### 6. [carry-over, still open — round-1 #14] @escaping/attributed parameter types produce invalid `SnapshotConfiguration<(@escaping () -> Void)>`
- Severity: low
- File: Sources/SnapshotsMacros/Support/_Helpers/FunctionSignatureSyntax+Convenience.swift:12
- Failure scenario: unchanged by the fix commits. `parameterClauseAsTuple` copies each parameter's type verbatim (`.init(type: $0.type)`). For a parameterised `@SnapshotTest` with configurations whose parameter is `@escaping () -> Void`, the generated generic becomes `SnapshotConfiguration<(@escaping () -> Void)>` — `@escaping` is illegal in generic-argument/tuple-element position, a parse/type error in generated code with no diagnostic.
- Evidence: `FunctionSignatureSyntax+Convenience.swift:12-18`, consumed by `SnapshotTest.swift:170` and `TestFunction.swift:17-22`. Only reachable when a configuration is supplied.
- Suggested fix: strip parameter-only type attributes (`@escaping`/`@autoclosure`) when building the tuple, and diagnose `inout`/variadic parameters as unsupported.
- needs_dynamic_verification: false

### 7. [carry-over, still open — round-1 #12] Source-empty `#if` branch is dropped from the rewritten IfConfig, yielding `#else`-first invalid output
- Severity: low
- File: Sources/SnapshotsMacros/SnapshotTest/_Support/IfConfig.swift:27
- Failure scenario: 1f9ef19 only touched `blockItemTestExprs` (IfConfig.swift:71-90); the clause rewrite at IfConfig.swift:27-32 is unchanged and guards on `clause.elements?.as(MemberBlockItemListSyntax.self)`, returning nil otherwise, so a truly source-empty branch is dropped from the clause list. If that empty branch is FIRST (the "skip on X" pattern: `#if targetEnvironment(macCatalyst) #else @SnapshotTest ... #endif`), the reassembled `IfConfigDeclSyntax` begins with `#else` — invalid Swift, a compile error in generated code. Note the asymmetry: a filtered-empty branch (has non-snapshot members) IS preserved with a warning comment (lines 39-52); only source-empty branches break.
- Evidence: IfConfig.swift:27-32 (guard + return nil, unchanged per `git show 1f9ef19 -- .../IfConfig.swift`); reassembly IfConfig.swift:62; empty-branch comment machinery for the preserved case IfConfig.swift:39-57. No fixture exercises a source-empty branch.
- Suggested fix: in the clause compactMap, when elements is absent/non-member, keep the clause with an empty `CodeBlockItemList` plus the existing warning comment instead of returning nil.
- needs_dynamic_verification: true

### 8. [carry-over, still open — round-1 #11] Generic suites / generic test functions generate non-compiling code with no diagnostic
- Severity: low
- File: Sources/SnapshotsMacros/SnapshotSuite/SnapshotSuite.swift:15
- Failure scenario: no generic-parameter or where-clause inspection was added anywhere under `Sources/SnapshotsMacros`. `@SnapshotSuite struct Foo<T> { ... }` nests the generated `@Suite` struct inside a generic type (rejected by swift-testing) and the peer container's `Foo().makeView()` cannot infer `T`. `canContinueAfterSanityChecks` has no generic guard.
- Evidence: `canContinueAfterSanityChecks.swift` performs only extension/display-name/`@Suite` checks; no `genericParameterClause`/`genericWhereClause` reference anywhere in `Sources/SnapshotsMacros`; suite codegen `SnapshotSuite.swift:11-19,40-66`; container instance call `SnapshotViewGenerator.swift:67-72`.
- Suggested fix: diagnose an error in `canContinueAfterSanityChecks` when the annotated type (or a test function) has a `genericParameterClause` or `genericWhereClause`.
- needs_dynamic_verification: true

### 9. Async-init diagnostic diagnoses but does not `return nil`, emitting the (also-broken) test wrapper alongside the error — inconsistent with sibling guards
- Severity: improvement
- File: Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:121
- Failure scenario: the non-instantiable guard (Test.swift:96-105) and the parameterised-without-config guard (Test.swift:138-143) both `return nil` after diagnosing, so no further generated code is produced for that function. The async-init guard (Test.swift:117-125) diagnoses but then falls through and generates the `_snapshotTest` wrapper anyway. The build fails either way (a hard error is already present), so this is not a correctness bug, but it emits extra broken code and is inconsistent with the two neighbouring guards.
- Evidence: Test.swift:117-125 has no `return nil` after `addAsyncInitialiserDiagnostic`, unlike Test.swift:104 and Test.swift:142.
- Suggested fix: add `return nil` after `addAsyncInitialiserDiagnostic`, matching the sibling guards.
- needs_dynamic_verification: false

### 10. Display-name collision fix (finding 2) does not cover two tests given the SAME explicit display name
- Severity: improvement
- File: Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:190
- Failure scenario: `makeDisplayNameOverride` returns nil as soon as a test has its own display name (Test.swift:189-192), so it only disambiguates the suite-fallback case. Two tests with identical EXPLICIT names — `@SnapshotTest("Same") func a()` and `@SnapshotTest("Same") func b()` — both bake `displayName "Same"` into their containers and share the same reference artifact (the same class of collision finding 2 addressed, just user-induced). Not silent like the fallback case, but still an unguarded collision.
- Evidence: `makeDisplayNameOverride` guard Test.swift:189-192 (own display name -> no override); peer bakes `testDisplayName` first in the fallback chain SnapshotTest.swift:154-157; artifact naming derives from `displayName`. `suiteFallbackTestCount` (Test.swift:220-236) counts only fallback (no-display-name) tests, so explicit duplicates are never detected.
- Suggested fix: optionally diagnose (warning) when two or more `@SnapshotTest` functions in a suite resolve to the same effective display name, whether via explicit names or the fallback.
- needs_dynamic_verification: false
