# Audit findings: legacy-macro-expansion

Static review of the legacy `@SnapshotSuite`/`@SnapshotTest` macro expansion path (`Sources/SnapshotsMacros/SnapshotSuite`, `Sources/SnapshotsMacros/SnapshotTest`, and shared `_Support` helpers). 16 findings, none overlapping the 6 pre-confirmed bugs: 2 high (one a regression introduced by this branch's sync-assertion refactor, one a display-name collision that corrupts snapshot artifacts), 9 medium (parameter/availability/type mismatches and silent-drop cases producing non-compiling or silently-skipped generated code), 3 low (edge-case codegen bugs), and 2 improvement items (a refuted escalation hotspot needing a coverage fixture, plus general hygiene/dead-code cleanup).

## High

### 1. Async legacy `@SnapshotTest` functions (and async suite inits) generate non-compiling code since the sync assertion refactor
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/_Support/SnapshotViewGenerator.swift:88`
- **Failure scenario**: Any legacy `@SnapshotTest func makeView() async [throws] -> some View` (or a suite whose first init is async) makes the macro emit `makeValue: { await Suite().makeView() }`. Since commit `9993f02` (this branch), all three runtime `SnapshotViewGenerator.init` overloads take a synchronous `@MainActor (ConfigurationValue) throws -> ...` makeValue; an async closure cannot convert to a sync function type, so the generated peer enum fails to compile.
- **Evidence**: Macro emits await at `SnapshotViewGenerator.swift:88` (`isAsync` from `SnapshotSuite/_Support/Declaration.swift:25-27`). Runtime is now sync-only: `Sources/SnapshotTestingMacros/SnapshotViewGenerator/SnapshotViewGenerator.swift:15`, `+SwiftUI.swift:9`, `+UIView.swift:7` (all `throws ->`, no `async`). Pre-refactor (`git show 531ec99:.../SnapshotViewGenerator.swift`) had `async throws ->`. Async fixtures were deleted in `647f304`; the remaining unit test asserts the now-broken text: `Tests/SnapshotsUnitTests/SnapshotSuite/FunctionModifiers/SnapshotSuiteTests+FunctionModifiers+Async.swift:39-41`.
- **Suggested fix**: Restore async `makeValue` overloads on `SnapshotViewGenerator` (await before entering the sync pipeline, as `ExpectSnapshotAdapter` does), or diagnose async legacy tests explicitly. Re-add a compiled integration fixture for async/throws legacy tests.
- **needs_dynamic_verification**: false

### 2. Suite display name overrides every test's displayName, colliding reference artifacts for multi-test named suites
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/SnapshotTest.swift:61`
- **Failure scenario**: `displayName = testDisplayName ?? suiteDisplayName ?? functionName`. A `@SnapshotSuite("Some name")` with two or more `@SnapshotTest` functions lacking per-test display names gets identical `displayName` on every generator. Artifact test names derive from displayName + size/theme, and the snapshot directory is shared per source file, so both tests read/write the same reference file — persistent false failures, and in record-all mode silent overwrite.
- **Evidence**: Fallback chain `SnapshotTest.swift:59-62`. Artifact naming: `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/AssertionRequestGenerator.swift:36`, `NameAssertionRequestGenerator.swift:42-51`. Shared directory: `AssertionRequestGenerator.swift:51-75`. Fixture proving substitution: `Tests/SnapshotsUnitTests/SnapshotSuite/Parameters/SnapshotSuiteTests+Parameters+DisplayName.swift:37`.
- **Suggested fix**: Never substitute the suite display name for a test's displayName; use the function name (suite name already appears via `@Suite`), or combine `suiteDisplayName + "/" + functionName`.
- **needs_dynamic_verification**: false

## Medium

### 3. Parameterised `@SnapshotTest` without configurations generates `.none` vs `SnapshotConfiguration<(Params)>` type mismatch
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/_Support/TestFunction.swift:20`
- **Failure scenario**: A parameterised `@SnapshotTest` function with no `configurations:`/`configurationValues:` argument gets `configuration: .none` substituted at the call site, but the container's `makeGenerator` expects `SnapshotConfiguration<(P1,...)>` while `.none` is `SnapshotConfiguration<Void>` — a hard compile error with no diagnostic pointing at the real cause. Repo's own fixture bakes the broken output in.
- **Evidence**: `TestFunction.swift:19-27`; `.none` substitution `Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:68-70`; generic from tuple `SnapshotTest.swift:66-72,29-31`; `.none` type `Sources/SnapshotTestingMacros/SnapshotConfiguration/SnapshotConfiguration.swift:57-59`; fixture `Tests/SnapshotsUnitTests/SnapshotSuite/SnapshotSuiteTests+NoParameters+Valid.swift:115,176-187`.
- **Suggested fix**: Diagnose (error) when the function has parameters and no configurations expression was found, instead of emitting `.none`. Also simplify the degenerate second disjunct on line 20.
- **needs_dynamic_verification**: false

### 4. `@available` on a test function is copied to the generated test but not to the peer container, whose makeValue calls the gated function
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/SnapshotTest.swift:8`
- **Failure scenario**: `@SnapshotTest @available(iOS 26.0, *) func myView() -> some View` compiles the generated test with `@available` but the peer `__generator_container_myView` enum has no attributes, so its `makeValue: { Suite().myView() }` calls the gated function unguarded — "only available in iOS 26.0 or newer" at the availability floor.
- **Evidence**: Container emitted without attributes `SnapshotTest.swift:6-23`; `@available` forwarded only to the suite-side test `_Support/Test.swift:20-39,169-184`; fixture `Tests/SnapshotsUnitTests/SnapshotTest/SnapshotTestTests+Attributes.swift:66-121`.
- **Suggested fix**: Forward `@available` attributes onto the generated container enum as well.
- **needs_dynamic_verification**: false

### 5. `configurationValues:` declared as any `Collection` but the parser is Array-only
- **File:line**: `Sources/SnapshotTestingMacros/MacroDefinitions/SnapshotTestMacroDefinition.swift:363`
- **Failure scenario**: The macro signature accepts `C: Collection & Sendable`, inviting e.g. `configurationValues: 1...3` or a `Set`, but `SnapshotConfigurationParser.parse` only has `[T]`/`[SnapshotConfiguration<T>]`/closure overloads — "no exact matches in call to static method parse" in generated code.
- **Evidence**: Declarations `SnapshotTestMacroDefinition.swift:363-367,400-405`; parser overloads `Sources/SnapshotTestingMacros/SnapshotConfiguration/SnapshotConfigurationParser.swift:16,20,26,32`; expansion path `Sources/SnapshotsMacros/SnapshotTest/_Support/TestMacro.swift:20-31`.
- **Suggested fix**: Add a generic `Collection` overload to the parser, or narrow the macro declarations to `[C.Element]`.
- **needs_dynamic_verification**: false

### 6. nil or non-literal display-name arguments silently reclassified as traits and boxed
- **File:line**: `Sources/SnapshotsMacros/Support/_Types/SnapshotMacroArguments.swift:20`
- **Failure scenario**: Trait detection treats every unlabeled non-string-literal argument as a trait. `@SnapshotSuite(nil, .record)` is legal per the nullable `String?` overloads, but `nil` becomes a trait -> `__SuiteTraitBox(nil).wrapped` fails ("nil is not compatible with expected argument type any SuiteTrait"). Same for any non-literal display name; interpolated literals silently fall back to the function name instead of erroring.
- **Evidence**: Filter `SnapshotMacroArguments.swift:15-24`; boxing `SnapshotSuite.swift:121-128`, `_Support/Test.swift:161-166`; nullable overloads across `SnapshotSuiteMacroDefinition.swift:97-100` and `SnapshotTestMacroDefinition.swift:185-189,263-267,331-335,400-404`; interpolation returns nil via `representedLiteralValue` (`SnapshotTest.swift:120-128`).
- **Suggested fix**: Treat a leading `NilLiteralExprSyntax` as an absent display name; diagnose non-literal display-name expressions; support or diagnose interpolated literals.
- **needs_dynamic_verification**: false

### 7. Return-type support is exact-string matched; view-ish spellings silently untested, non-view returns break the unchecked peer
- **File:line**: `Sources/SnapshotsMacros/Support/Constants/Constants+Configuration+supportedReturnTypes.swift:6`
- **Failure scenario**: Suite side only generates a test for a literal trimmed return type in `{some View, UIView, UIViewController, NSView, NSViewController}`. `-> AnyView`, `-> Text`, `-> MyViewAlias`, `-> SwiftUI.AnyView` are silently excluded (warning only fires when the whole suite is invalid). Meanwhile the peer has no return-type check, so a genuinely unsupported return produces a cryptic "no exact matches in call to initializer" instead of a macro diagnostic.
- **Evidence**: Gate `Support/_Helpers/FunctionDeclSyntax+Convenience.swift:16-26` + `Constants+Configuration+supportedReturnTypes.swift:5-13`; silent drop `SnapshotTest/_Support/TestBlock.swift:21-29`; whole-suite-only warning `SnapshotSuite.swift:72-93`; peer has no check `SnapshotTest.swift:41-82`; fixture `Tests/SnapshotsUnitTests/SnapshotSuite/SnapshotSuiteTests+Diagnostics.swift:12-68`.
- **Suggested fix**: Emit a per-function diagnostic for unsupported return types on both suite and peer sides.
- **needs_dynamic_verification**: false

### 8. `@SnapshotTest` on a non-function declaration is dropped with total silence
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/SnapshotTest.swift:45`
- **Failure scenario**: `@SnapshotTest var myView: some View { ... }` produces nothing anywhere — no error, no test — because the peer bails on the `FunctionDeclSyntax` guard (marked with a `#warning` TODO) and the suite side only considers function members. User believes coverage exists; none is generated.
- **Evidence**: Peer guard `SnapshotTest.swift:41-47`; suite-side function-only filter `_Support/TestBlock.swift:21-36`, filtered `SnapshotSuite.swift:73`; no attachment restriction `SnapshotTestMacroDefinition.swift:27-28`.
- **Suggested fix**: Diagnose an error when the annotated declaration is not a function.
- **needs_dynamic_verification**: false

### 9. Bare `@SnapshotTest` without an enclosing `@SnapshotSuite` silently emits a dead (sometimes non-compiling) container
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/SnapshotTest.swift:50`
- **Failure scenario**: No check for an enclosing `@SnapshotSuite`/`@Suite` ancestor. Inside a plain type, the peer container enum is still emitted but no `_snapshotTest` is generated, so the function never runs as a test, silently. In the enum fixture case the dead container additionally fails to compile (`MyTests().aTest()` called on an enum).
- **Evidence**: Init requirements `SnapshotTest.swift:41-53`; fixture `Tests/SnapshotsUnitTests/SnapshotTest/SnapshotTestTests+MacroAttachments.swift:10-51` (expansion lines 32-47); nested case in disabled Subsuite fixtures.
- **Suggested fix**: Walk `context.lexicalContext` for an enclosing `@SnapshotSuite` decl; warn and skip the peer if absent.
- **needs_dynamic_verification**: false

### 10. Instantiability assumptions: required-param/private inits, namespaced `SnapshotConfiguration` init params, `@SnapshotSuite` on extensions all generate broken calls
- **File:line**: `Sources/SnapshotsMacros/SnapshotSuite/_Support/Declaration.swift:33`
- **Failure scenario**: (1) `isInitializable` only checks struct/class/actor — a required-param-only init still passes, generating `Suite().test()` that fails to compile. (2) `initConfigurationToken` matches only unqualified `IdentifierTypeSyntax` named `SnapshotConfiguration`; a `MemberTypeSyntax` (`SnapshotTestingMacros.SnapshotConfiguration<Void>`) or typealias silently fails the match, omitting the configuration argument from the generated call. (3) `@SnapshotSuite extension Foo { @SnapshotTest func ... }`: peer bails because `ExtensionDeclSyntax` has no identifier name, but the suite side still references the (unemitted) container -> "cannot find `__generator_container_x` in scope". The diagnostic that does fire for some of these is only a warning while broken code is still emitted.
- **Evidence**: `Declaration.swift:19-23,33-42`; call-site omission `SnapshotTest/_Support/SnapshotViewGenerator.swift:62-75`; extension gap `Support/_Helpers/Syntax+Name.swift:4-9`, peer bail `SnapshotTest.swift:49-53`, suite reference `_Support/Test.swift:64-66`; warning-only diagnostic `_Support/Test.swift:81-88,120-147`, `Diagnostics.swift:265-272`.
- **Suggested fix**: Match init parameter by base type name including `MemberTypeSyntax`; verify a callable init exists before generating instance calls and diagnose otherwise; diagnose `@SnapshotSuite` on extensions.
- **needs_dynamic_verification**: false

### 11. Generic suites and generic test functions generate non-compiling code with no diagnostic
- **File:line**: `Sources/SnapshotsMacros/SnapshotSuite/SnapshotSuite.swift:15`
- **Failure scenario**: Neither macro inspects generic parameter/where clauses. `@SnapshotSuite struct Foo<T> { ... }` nests the generated `@Suite` struct inside a generic type where Swift Testing rejects `@Test`/`@Suite`, and `Foo()` in `makeValue` cannot infer `T`. A generic test function similarly references an undeclared `T` in the container's generic argument.
- **Evidence**: No generic-clause handling anywhere under `Sources/SnapshotsMacros` (confirmed via search); codegen `SnapshotSuite.swift:11-19,40-66`; container codegen `SnapshotTest.swift:6-39,64-72`; instance call `_Support/SnapshotViewGenerator.swift:62-66`.
- **Suggested fix**: Diagnose an error in `canContinueAfterSanityChecks` when the annotated type or function has generic parameters/where clauses.
- **needs_dynamic_verification**: true

## Low

### 12. `#if` clause with an empty source branch is dropped from the rewritten IfConfig
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/_Support/IfConfig.swift:28`
- **Failure scenario**: A source-empty branch (e.g. `#if targetEnvironment(macCatalyst) #else @SnapshotTest ... #endif`) has `elements` parsed as non-`MemberBlockItemListSyntax`, so the clause is dropped from the compactMap. If that empty branch is first, the generated member starts with `#else`/`#elseif` — unparseable, a compile error in generated code for the reasonable "skip on X" pattern.
- **Evidence**: `IfConfig.swift:27-33` (guard + `return nil`), reassembly at line 62 preserves the remaining pound tokens; empty-branch comment machinery at lines 39-52 shows non-empty branches are handled correctly, underscoring the asymmetry.
- **Suggested fix**: Keep the clause with an empty `CodeBlockItemList` plus the existing warning comment instead of returning nil.
- **needs_dynamic_verification**: true

### 13. Overloaded `@SnapshotTest` functions produce duplicate `__generator_container_<name>` enums
- **File:line**: `Sources/SnapshotsMacros/Support/Constants/makeContainerName.swift:6`
- **Failure scenario**: Container name derives solely from the base function name. Two `@SnapshotTest` overloads (e.g. one plain, one parameterised) both emit `enum __generator_container_makeView` in the same scope -> "invalid redeclaration". Suite-side generated test names may also collide when configuration arity matches.
- **Evidence**: `makeContainerName.swift:5-7`, used identically by `SnapshotTest.swift:64` and `_Support/Test.swift:98`; file has a `#warning("TODO: Can we do better than this?")` acknowledging the constraint.
- **Suggested fix**: Include a stable signature hash in the container name on both sides, or diagnose overloaded `@SnapshotTest` functions.
- **needs_dynamic_verification**: false

### 14. Variadic, inout, or attributed parameter types produce invalid tuple generic arguments
- **File:line**: `Sources/SnapshotsMacros/Support/_Helpers/FunctionSignatureSyntax+Convenience.swift:12`
- **Failure scenario**: `parameterClauseAsTuple` copies each parameter's type syntax verbatim into a tuple generic argument. `func v(items: Int...)` yields `SnapshotConfiguration<(Int...)>`; `func v(action: @escaping () -> Void)` yields `(@escaping () -> Void)` — both invalid in generic-argument position, causing parse/type errors in generated code with no diagnostic.
- **Evidence**: `FunctionSignatureSyntax+Convenience.swift:12-18` (`.init(type: $0.type)`), consumed at `SnapshotTest.swift:66-72` and `_Support/TestFunction.swift:17-23`.
- **Suggested fix**: Strip parameter-only type attributes (`@escaping`/`@autoclosure`) and diagnose variadic/inout parameters as unsupported.
- **needs_dynamic_verification**: false

### 15. macOS-specific compile break claim: DENIED — legacy is compiled out on macOS; failure is most plausibly the platform-neutral bugs above
- **File:line**: `Tests/SnapshotsIntegrationTests/SnapshotSuite/LegacySnapshotSuiteMigration.swift:1`
- **Failure scenario**: N/A (confirm/deny result). All symbols the legacy expansion references are platform-neutral or properly `canImport`-gated. A dedicated macOS integration target compiled ungated legacy fixtures (including async ones) at commit `531ec99`, so the expansion was macOS-clean historically. Today both remaining legacy fixtures and the repetition fixture are `#if canImport(UIKit)`-gated, so no macOS build currently compiles legacy expansion at all — any observed "doesn't compile on macOS" report is most plausibly one of the platform-neutral bugs above (finding 1 is the top suspect) rather than a macOS-specific mechanism.
- **Evidence**: Gates: `Tests/SnapshotsIntegrationTests/SnapshotSuite/LegacySnapshotSuiteMigration.swift:1`, `Tests/SnapshotsIntegrationTests/SnapshotTest/LegacySnapshotTestMigration.swift:1`, `Tests/SnapshotsIntegrationRepetitionTests/LegacySnapshotRepetitionMigration.swift:1` (+ Placeholder.swift). Historical macOS compile: `git ls-tree 531ec99 Tests/SnapshotsIntegrationTestsMacOS/SnapshotSuite/` (includes `SnapshotSuite+AsyncThrows.swift`). Platform-neutral runtime surface: `UniversalTypes.swift:13-22`, `AppKit+Convenience.swift:14-19`, `SnapshotViewGenerator+SwiftUI.swift:1`.
- **Suggested fix**: Run a one-file macOS compile probe of a bare legacy suite with the `canImport` gate removed to close definitively; fix whichever platform-neutral bug surfaces rather than re-gating by platform.
- **needs_dynamic_verification**: true

## Improvement

### 16. Escalation verdict: multi-parameter `$0`/`$1` closure arity is NOT a miscompile, but zero compiled coverage exists for 2+ parameter legacy tests
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/_Support/SnapshotViewGenerator.swift:54`
- **Failure scenario (coverage gap, not a bug)**: For `func makeMyView(string: String, int: Int)` the macro emits `{ Tests().makeMyView(string: $0, int: $1) }`. Runtime takes a single tuple parameter `((String, Int)) throws -> ...`, and Swift's implicit tuple-splat rule (post-SE-0110) makes multi-`$N` closures over a single tuple argument legal, so this compiles. However no integration fixture exercises 2+ parameter legacy tests on any platform — only unit (text-only) coverage exists.
- **Evidence**: `SnapshotViewGenerator.swift:54-60`; single-tuple runtime param `Sources/SnapshotTestingMacros/SnapshotViewGenerator/SnapshotViewGenerator.swift:15` with `ConfigurationValue` from `SnapshotTest.swift:66-72`; text-only coverage `Tests/SnapshotsUnitTests/SnapshotTest/Configurations/SnapshotTestTests+Configurations+Valid.swift:112-216`; compiled fixtures are all 0/1-param (`Tests/SnapshotsIntegrationRepetitionTests/LegacySnapshotRepetitionMigration.swift:17-25`, `Tests/SnapshotsIntegrationTests/SnapshotTest/LegacySnapshotTestMigration.swift:19-26`).
- **Suggested fix**: Add a compiled integration fixture with a two-parameter `@SnapshotTest(configurations:)` function to lock in the tuple-splat dependence.
- **needs_dynamic_verification**: false

### 17. Silent attribute dropping on generated tests; dead checks and stale disabled fixtures
- **File:line**: `Sources/SnapshotsMacros/SnapshotTest/_Support/Test.swift:21`
- **Failure scenario (hygiene, not a compile bug)**: (1) Only `@MainActor`/`@available` are forwarded to the generated test; other attributes on the original function are silently discarded. (2) `canContinueAfterSanityChecks` has a dead `guard passesWarningChecks else { return true }` plus `#warning` TODOs admitting no error checks exist. (3) `TestFunction.swift:20`'s second disjunct is unreachable (see finding 3). (4) Stale disabled fixture `SnapshotSuiteTests+Parameters+DisplayName.swift:238` asserts an obsolete API shape that no longer matches the current generator. (5) Orphaned legacy snapshot PNGs remain under `Tests/SnapshotsIntegrationTests/SnapshotTest/__Snapshots__/SnapshotTest+EscapedIdentifiers/` with no corresponding source file.
- **Evidence**: Attribute filter `_Support/Test.swift:20-24`; dead guard/TODOs `SnapshotSuite/_Support/canContinueAfterSanityChecks.swift:6,19,28`; stale fixture `Tests/SnapshotsUnitTests/SnapshotSuite/Parameters/SnapshotSuiteTests+Parameters+DisplayName.swift:238-287`; orphaned artifacts confirmed via `fd` listing.
- **Suggested fix**: Warn on dropped attributes (or document the whitelist), remove dead code, refresh/remove stale disabled fixtures, prune orphaned snapshot artifacts.
- **needs_dynamic_verification**: false
