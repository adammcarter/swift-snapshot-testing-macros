# Audit findings: sizing-request-generators

Reviewed the sizing/request fan-out subsystem (`RequestGenerator/**` + `SizesSnapshotTrait` family) against the pinned pointfree 1.19.1 sources. The pipeline is deterministic per assertion call (sequential accumulator, fixed `[.light, .dark]` order, device table matches pointfree's `ViewImageConfig` exactly), but three high-severity findings undermine that determinism or silently drop documented behavior across process/platform boundaries, four medium findings affect naming/validation correctness, and one improvement finding covers test-coverage gaps. No tracked files were modified; no builds or tests were run as part of this analysis.

---

## 1. Native `#expectSnapshot` path leaves pointfree's `.N` counter process-global: order-dependent reference assignment across parallel tests and broken repeat-iterations

**Severity:** high
**File:** `Sources/SnapshotTestingMacros/Assertion/Asserter.swift:149`
**needs_dynamic_verification:** true

**Failure scenario:** Every generated request is executed via `SnapshotTesting.verifySnapshot(named: nil)`, so the reference identifier is pointfree's positional counter. Under Swift Testing (`Test.current != nil`) that counter is the task-local `File.counter`, and the native pipeline never binds it, so all tests in the process share the single unbound default `Counter` instance, which is also never reset. Two consequences: (1) any two assertions in the same file whose `snapshotDirectory`+`testName` coincide share one counter key, and since Swift Testing runs tests/cases in parallel, which assertion gets `.1` vs `.2` depends on scheduling — reference files swap owners between runs, producing flip-flopping false failures. (2) Repeat-iterations (`Tests/SnapshotsIntegrationRepetitionTests.xctestplan` sets `fixedIterations: 3`, run in CI by `.github/workflows/run-tests.yaml:109-113`) increment the same key per iteration, so iteration 2 of `ExpectSnapshotRepetitionTests.singular` would look for `singular_min-size_light.2.png`, which does not exist (all committed refs end `.1`). This is a regression vs the legacy path: the deprecated `@SnapshotSuite` macro auto-applies `.pointfreeSnapshots` (pointfree's `_SnapshotsTestTrait`), whose `TestScoping` binds a fresh `File.Counter` per test invocation, keeping iterations at `.1`; the native `@Suite`/`@Test` + `#expectSnapshot` surface deliberately drops that trait and replaces it with nothing.

**Evidence:** `Asserter.swift:145-157` calls `SnapshotTesting.verifySnapshot(..., named: nil, ...)`. Pinned dependency (`Package.resolved`: swift-snapshot-testing 1.19.1, revision `05b6f05`): `AssertSnapshot.swift:324-331` — when `name==nil`, `identifier = counter.next(for: snapshotDirectoryUrl.appendingPathComponent(testName).absoluteString)`; `AssertSnapshot.swift:555-565` — with `Test.current != nil` the counter is `File.counter`, a `@TaskLocal` whose default (`AssertSnapshot.swift:613`) is one shared instance when unbound; the only binding in pointfree is `SnapshotsTestTrait.swift:54` (`File.$counter.withValue(File.Counter())` inside `_SnapshotsTestTrait`'s `TestScoping`); the `CleanCounterBetweenTestCases` observer (`AssertSnapshot.swift:296-302, 591-609`) is registered only when `Test.current == nil` and resets `_counter`, not the task-local. In this repo, `.pointfreeSnapshots` is applied only by the legacy macro (`Sources/SnapshotsMacros/SnapshotSuite/SnapshotSuite.swift:113`); nothing in the native pipeline (`ExpectSnapshotAdapter` → `assertSnapshotSync` → `Asserter.assertSnapshotsSync`, `Asserter.swift:8-18`, whose `withSnapshotTesting` per `SnapshotTestingConfiguration.swift:26-40` binds only `record`/`diffTool`) touches `File.$counter`. The repetition suite contrast is committed in-repo: `Tests/SnapshotsIntegrationRepetitionTests/ExpectSnapshotRepetitionTests.swift` (native, no counter scoping) vs `LegacySnapshotRepetitionMigration.swift` (legacy `@SnapshotSuite`, counter scoped).

**Suggested fix:** Stop relying on the positional counter for the native path: pass an explicit `named:` identifier (fold a stable discriminator into `named:` so identifier = sanitized name and the counter is bypassed), or re-apply pointfree's counter scoping per test in the native pipeline (expose and use a per-test `File.Counter` binding). If file naming must stay `<testName>.1.png`, use `named:` deterministic identifiers derived from the request index within the assertion call.

---

## 2. Raw display name flows into `testName` while dedup happens pre-sanitization: distinct names that sanitize identically silently share one reference file

**Severity:** high
**File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/NameAssertionRequestGenerator.swift:42`
**needs_dynamic_verification:** false

**Failure scenario:** `testName(for:)` joins `configurationName`, the RAW `context.name` (only slash-path segments are normalized; ordinary names are not), and size/theme descriptions. Downstream, pointfree writes the file as `sanitizePathComponent(testName)` (`\W+` → `"-"`) but keys its `.N` counter on the UNsanitized `testName`. The package's own duplicate-name guard (`SnapshotExecutionContext.resolvedAssertionName`, `SnapshotExecutionContext.swift:18-35`) also dedups RAW names. So two assertions whose raw names differ but sanitize identically — e.g. `named: "menu view"` and `named: "menu-view"` in one test — produce: distinct raw names (no `-2` suffix), distinct counter keys (both get identifier `.1`), but the SAME final file `menu-view_min-size_light.1.png`. In record mode the second silently overwrites the first (stale approval looks valid); in assert mode the second view is compared against the first view's reference, yielding a false failure or, worse, a false pass.

**Evidence:** `NameAssertionRequestGenerator.swift:42-51` joins `context.name` raw; `normalizedPathName` (lines 67-81) only rewrites names with ≥2 slash components, and `resolvedContext` (line 13) skips even that when `configurationName != nil`. `context.name` is the raw displayName (`AssertionRequestGenerator.swift:36`). Dedup is raw-string-based: `SnapshotExecutionContext.swift:20-34`. Pointfree 1.19.1 `AssertSnapshot.swift:324-338`: counter key uses unsanitized `testName` (line 329) while the file component is sanitized (line 333, `sanitizePathComponent` at 569-574: `\W+` → `"-"`, trim edge dashes) — so `"menu view_min-size_light"` and `"menu-view_min-size_light"` have different counter keys (both `.1`) but the identical sanitized filename `"menu-view_min-size_light"`.

**Suggested fix:** Normalize name components with `SnapshotNameNormalizer` (or pointfree-equivalent sanitization) BEFORE both the `SnapshotExecutionContext` dedup and the `testName` join, so uniqueness is enforced on the exact string that becomes the filename; alternatively assert/collision-check final sanitized (directory, fileName) pairs per assertion run and fail loudly on collision.

---

## 3. AppKit: `Size.scale` / device scale is computed but never applied — the documented scale parameter is a silent no-op on macOS

**Severity:** high
**File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/StrategyAssertionRequestGenerator.swift:53`
**needs_dynamic_verification:** false

**Failure scenario:** `ThemeAssertionRequestGenerator` resolves `displayScale = sizeTrait.scale ?? windowScale` and threads it through `NameAssertionRequestGenerator` into `StrategyAssertionRequestGenerator`, but on AppKit the image request is built as `.image(size: size)` with no traits/scale (and pointfree's `Snapshotting<NSViewController,NSImage>.image(precision:perceptualPrecision:size:)` has no scale hook at all). `displayScale` is only consumed by `makeTraits()`, which is `#if canImport(UIKit)`. So on macOS, `.sizes(width: 300, height: 200, scale: 2.0)` — documented in `SizesSnapshotTrait+Length+Init.swift:10` as "Use 2.0 for @2x... nil to inherit" with no platform caveat — and `Device.scale` from the device table silently do nothing; the rendered raster scale is whatever pointfree's `NSView` drawing picks up from the environment. Relatedly, the `NSScreen.main`-based `windowScale` fallback (`ThemeAssertionRequestGenerator.swift:43-45`) is dead code on this path. Note this is distinct from known bug (2) (`NSAppearance` never applied): that covers the theme half; this is the scale half — on the AppKit branch BOTH theme and displayScale parameters of the request are unused.

**Evidence:** `StrategyAssertionRequestGenerator.swift:50-61` (AppKit branch: `.image(size: size)` only; theme and displayScale unused), 67-82 (`makeTraits` UIKit-only — sole consumer of `displayScale`). Pointfree checkout `Snapshotting/NSViewController.swift:20-26`: `image(precision:perceptualPrecision:size:)` — no scale/appearance parameter. Scale plumbing that ends up dead on macOS: `SizesSnapshotTrait+Size.swift:14/29`, `SizesSnapshotTrait+Device.swift:71-73`, `ThemeAssertionRequestGenerator.swift:35-47`.

**Suggested fix:** On AppKit either (a) implement a custom image strategy that renders the `NSView` into an explicitly-scaled bitmap context honoring `displayScale`, or (b) reject/document scale on macOS (warn or throw when `scale != nil` on AppKit) so users are not led to believe @2x/@3x refs are being produced.

---

## 4. `recursiveDescription` strategy ignores the computed size and theme entirely — size/theme fan-out emits N×M refs whose names describe settings that were never applied

**Severity:** medium
**File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/StrategyAssertionRequestGenerator.swift:24`
**needs_dynamic_verification:** true

**Failure scenario:** For `.strategy(.recursiveDescription)`, the request is built with pointfree's default `.recursiveDescription`: on UIKit that is `recursiveDescription(on: .init(), size: nil, traits: .init())` — `prepareView` then uses the view controller's EXISTING frame size and empty traits; on AppKit it is a plain pullback with no size parameter at all. The `absoluteSize` computed by `SizeAssertionRequestGenerator` and the theme resolved by `ThemeAssertionRequestGenerator` are simply dropped. Concrete failure: `@Test(.sizes(devices: .iPhoneSE, .iPadPro12_9), .theme(.all), .strategy(.recursiveDescription))` emits 4 requests named `..._iPhoneSE_light/dark` and `..._iPadPro12_9_light/dark`, but all four descriptions are of the same un-resized, un-themed view controller — for the fully-fixed-size path the VC has never even been laid out (`absoluteSize(for:)` at `SizeAssertionRequestGenerator.swift:128-129` returns the `CGSize` without touching the view, contradicting the comment at lines 21-25 claiming the returned VC "has just gone through the layout process"). Users get 4 nominally device/theme-differentiated text refs with zero actual differentiation, and the size embedded in the file name is a lie.

**Evidence:** `StrategyAssertionRequestGenerator.swift:23-33` — recursiveDescription branch passes neither size, theme, nor displayScale (contrast the `.image` UIKit branch, lines 37-49, which passes size and `makeTraits()`). Pointfree checkout `UIViewController.swift:129-163` — default config `.init()` (size nil) means `prepareView` sizes from `viewController.view.frame.size` and traits `.init()`; `NSViewController.swift:29-35` — recursiveDescription has no size/traits at all. `SizeAssertionRequestGenerator.swift:126-140` — (`.fixed`,`.fixed`) never touches the view; comment at 21-25 is wrong for that branch.

**Suggested fix:** Build the recursiveDescription strategy with the computed values: on UIKit use `.recursiveDescription(on: .init(), size: size, traits: makeTraits())`; on AppKit pre-size the view (`view.frame.size = size`) before description or add a sized wrapper. Alternatively, collapse the size/theme fan-out to a single request when the strategy cannot express them. Also fix the stale comment in `SizeAssertionRequestGenerator.accumulateRequests`.

---

## 5. Public `Size` init derives `testNameDescription` from the case pattern only — multiple fixed sizes in one test are distinguishable solely by the positional `.N` counter

**Severity:** medium
**File:** `Sources/SnapshotTestingMacros/Traits/SizesSnapshotTrait+Size.swift:37`
**needs_dynamic_verification:** false

**Failure scenario:** `Size.init(width:height:scale:)` sets `testNameDescription` to just `"fixed-size"`/`"min-height"`/`"min-width"`/`"min-size"` — the numeric values never appear. The doc example on the `.sizes` trait itself (`SizesSnapshotTrait+Size+Init.swift:15-18`) therefore produces two requests with IDENTICAL testNames per theme, disambiguated only by pointfree's positional `.1`/`.2` suffix, i.e. by array order through the accumulator for-loop. Refs are stable only while the sizes list never changes: inserting a size in the middle, removing the first, or reordering silently re-maps every subsequent `.N` to a different geometry — in assert mode both sizes then diff against the wrong references; in record mode everything is silently re-recorded so stale approvals look intentional. There is no way to tell from the file name which geometry a ref represents. (Device-derived sizes avoid this because their description embeds the device name; scale is also excluded, so two sizes differing only by scale collide the same way.)

**Evidence:** `SizesSnapshotTrait+Size.swift:37-45` — description computed purely from the `(width,height)` case pattern; values and scale omitted. `NameAssertionRequestGenerator.swift:42-51` — testName joins that description. Ordering is the only disambiguator: `AccumulatedAssertionRequestGenerating.swift:13-21` sequential for-loop; pointfree counter assigns `.N` in call order (`AssertSnapshot.swift:324-331`). Doc example that triggers it: `SizesSnapshotTrait+Size+Init.swift:11-23`.

**Suggested fix:** Embed the concrete values in `testNameDescription` for the public init, e.g. `"300x200"` / `"w300-minh"` / `"minw-h200"` (+ `"@2x"` when `scale != nil`), mirroring how the device init embeds `device.debugDescription`. This makes names value-stable and order-independent; keep old strings only if ref-compat shims are needed.

---

## 6. Slash-path folder convention silently disabled for parameterized tests (`configurationName != nil`): the same name nests for plain tests but is flattened for configured ones

**Severity:** medium
**File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/NameAssertionRequestGenerator.swift:13`
**needs_dynamic_verification:** false

**Failure scenario:** `resolvedContext` applies the folder/file split only when `context.configurationName == nil`. A parameterized assertion like `#expectSnapshot(configuration, named: "Menu/Item")` keeps the raw `"Menu/Item"` as a single filename component: the final testName becomes `"<config>_Menu/Item_<size>_<theme>"` and pointfree's sanitizer turns the slash into a dash, while the identical `named:` value on a non-parameterized assertion creates a `Menu/` subfolder with file `Item_...`. The same convention (slash = subfolder, which the repo's own migration rewriter actively generates — `SnapshotMigrationRewriter.swift:915`) silently changes meaning depending on whether the test is parameterized, scattering refs for one logical group across different shapes. The raw slash also participates in pointfree's unsanitized counter key, so `"Menu/Item"` vs `"Menu-Item"` as configured display names collide on the same sanitized file with independent `.1` counters (same clobber class as finding 2).

**Evidence:** `NameAssertionRequestGenerator.swift:12-17` — guard `context.configurationName == nil` short-circuits the slash split; testName join at 42-51 then embeds the raw name. For the parameterized branch, `AssertionRequestGenerator.swift:30-33` sets `configurationName` + `testFolderName` (normalized displayName — slash becomes dash via `SnapshotNameNormalizer.folderComponent`, `SnapshotNameNormalizer.swift:4-8`), so the folder becomes `"Menu-Item"` rather than nested `Menu/Item`. Pointfree sanitization of the filename: `AssertSnapshot.swift:333, 569-574`. Slash convention generated by this repo's migration tooling: `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift:911-915`.

**Suggested fix:** Apply `normalizedPathName` to the display name regardless of `configurationName` — nest the folder under the (already-derived) `testFolderName` and use the final segment as the name, so `"A/B"` means the same thing in both modes. If intentionally unsupported for parameterized tests, normalize the slash out of the name explicitly (and document it) instead of letting the raw separator leak into `testName` and the counter key.

---

## 7. Zero/negative fixed lengths combined with `.minimum` are silently treated as "unconstrained" instead of erroring; negative fixed sizes are misreported as zero errors; scale is unvalidated

**Severity:** medium
**File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/SizeAssertionRequestGenerator.swift:151`
**needs_dynamic_verification:** false

**Failure scenario:** `compressedSizeWhenConstrained` uses `0` as the "no constraint" sentinel (`if width > 0` / `if height > 0`). Consequently `.sizes(width: .fixed(0))` — or a computed value that accidentally goes 0/negative — does not fail like the fixed×fixed path does (which throws `zeroWidth`); it silently drops the width constraint and measures the fully-compressed size, producing a passing snapshot at intrinsic width when the user asked for width 0/-50. The same inputs behave completely differently depending on the other dimension: `(.fixed(0), .fixed(200))` throws, `(.fixed(0), .minimum)` silently succeeds at intrinsic size. Related gaps: (a) negative fixed×fixed sizes fail the `width > 0` guard and are reported as `SizeError.zeroWidth` ("Zero width for snapshot"), misleading anyone debugging a sign error; (b) `Size.scale` (`SizesSnapshotTrait+Size.swift:29`) accepts 0, negative, and NaN — `scale: 0` (an easy typo for "inherit") flows into `UITraitCollection.displayScale` on UIKit with renderer-defined fallback behaviour rather than an error.

**Evidence:** `SizeAssertionRequestGenerator.swift:144-162` — default parameters `toWidth`/`toHeight = 0` and `if width > 0` / `if height > 0` guards conflate "absent" with "zero-or-negative requested"; call sites at 134-138 pass the user's fixed value directly. Guards at 84-94 run on the MEASURED result, so an unconstrained measurement that returns a positive intrinsic size passes without any indication the requested constraint was dropped; for fixed×fixed the guards throw `.zeroWidth`/`.zeroHeight` for negative inputs (error enum at 47-62 has no negative case). Scale is never validated anywhere between `SizesSnapshotTrait+Size.swift:26-46` and `StrategyAssertionRequestGenerator.swift:67-81`. Existing tests only cover fixed×fixed zeros (`SizeAssertionRequestGeneratorTests.swift:74-161`).

**Suggested fix:** Validate at `SizePair` construction (or `Size` init): throw a dedicated `SizeError.invalidLength(value)` for fixed ≤ 0 in ANY combination, and add `.negativeSize` instead of reusing `zeroWidth`/`zeroHeight`. Make `compressedSizeWhenConstrained` take `Optional<Double>` constraints instead of 0-sentinels. Validate scale (require `scale > 0 && scale.isFinite` or nil).

---

## 8. (Improvement) Test-coverage gaps: request ORDER (the sole `.N` disambiguator) is asserted via Set everywhere, the `.minimum` measurement path and name-collision/slash edge cases are untested, and all generator unit tests are macOS-only

**Severity:** improvement
**File:** `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/AssertionRequestPipelineTests.swift:40`
**needs_dynamic_verification:** false

**Failure scenario:** The determinism contract this whole subsystem leans on — requests emitted in sizes-array order × fixed `[.light,.dark]` theme order, because pointfree's `.N` counter is purely positional — has no test: every multi-request assertion compares `Set(requests.map(\.testName))` (`AssertionRequestPipelineTests.swift:40` and 78, `SizeAssertionRequestGeneratorTests.swift:40`, `ThemeAssertionRequestGeneratorTests.swift:18/31`), so a regression that reorders the fan-out would pass all tests while silently swapping every `.1`/`.2` reference pair. Also untested: the `.minimum` branches of `absoluteSize`/`compressedSizeWhenConstrained` (no unit test embeds and measures a view; only fixed×fixed error paths are covered), negative and `fixed(0)`+`.minimum` inputs, duplicate/identical `testNameDescription` sizes, names that sanitize identically, slash names with `configurationName` present, and single-component slash names ("Menu/"). Every generator unit test is wrapped in `#if os(macOS)` so the UIKit halves (`makeTraits`, `windowScale`, UIKit `absoluteSize`) have zero unit-level coverage — only integration snapshots exercise them.

**Evidence:** Set-based assertions: `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/AssertionRequestPipelineTests.swift:39-46, 77-84`; `SizeAssertionRequestGeneratorTests.swift:39-46`; `ThemeAssertionRequestGeneratorTests.swift:17-19`. Order-dependence of refs: `AccumulatedAssertionRequestGenerating.swift:16-18` + pointfree `AssertSnapshot.swift:328-331`. Platform gating: `#if os(macOS)` at line 1 of all five generator test files. Missing-case inventory from `SizeAssertionRequestGeneratorTests.swift` (only empty/zero fixed cases) and `NameAssertionRequestGeneratorTests.swift` (only the happy slash split at lines 42-51).

**Suggested fix:** Add order-sensitive assertions (compare arrays, not Sets) for the full pipeline fan-out; add unit tests for `.minimum` measurement using a fixed-intrinsic-size stub view (all four width/height combinations, plus `fixed(0)`/negative + `.minimum`), duplicate fixed sizes (document the `.1`/`.2` contract), sanitize-collision names, and slash names with a `configurationName`; lift or mirror the generator tests for UIKit in the iOS unit test target.
