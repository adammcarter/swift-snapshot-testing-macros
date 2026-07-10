# Audit round 2: DisplayNameOverrideArtifactTests.swift (untracked) exercises legacy @SnapshotSuite display-name-collision fix via AssertionRequestGenerator/SnapshotViewGenerator, not the sizing/request-fan-out surface itself

## Summary

Reviewed DisplayNameOverrideArtifactTests.swift (untracked) — the legacy @SnapshotSuite display-name-collision test that exercises `__overridingDisplayName` + `SnapshotViewGenerator` identity through `AssertionRequestGenerator`. Traced all three tests end-to-end through the full request-generation chain (Size -> Theme -> Name -> Strategy generators), `__overridingDisplayName` (SnapshotViewGenerator.swift:92-106), `makeDecoratedView`, `preserveFrameBasedSize`, the default task-local trait values, and the legacy macro's actual override emission (Test.swift:73, `makeDisplayNameOverride`:185-207).

RESULT: No correctness bug, no compile failure, no false/failing assertion. The file compiles (passing `any SnapshotViewGenerating` into the `some` parameter is the same implicit-existential-opening pattern already shipping at assertSnapshot.swift:12) and all three tests pass deterministically — the default `.minimum` size stays non-zero because `preserveFrameBasedSize` pins the fixture's 10x10 frame, the default theme `.all` yields light+dark so the sets are non-empty, and the override string "Some name/makeFirstView" faithfully models the macro's `<suite>/<function>` output. Test 2's `isDisjoint` robustly catches a broken displayName forward, and Test 3 covers fileID/filePath/line/column forwarding.

All four findings are test-quality/coverage gaps, not defects:
1. LOW — the override's async `makeViewControllerAsync` forward (load-bearing for async legacy suites with colliding fallback names) is never exercised because every fixture is sync, so a regression dropping it stays green.
2. IMPROVEMENT — Test 1 is tautological (proves determinism, not a real two-test collision) and its hard `#expect(==)` pins identical names as a required collision, which would block future source-location disambiguation.
3. IMPROVEMENT — determinism rides on default task-locals + live `.minimum` AppKit layout instead of scoping traits like the sibling tests.
4. IMPROVEMENT — `viewController.view != nil` is a near-tautology that under-verifies the forwarded closure.

## Verification

`swift test --filter SnapshotRuntimePreconditionTests`:
```
✔ Suite SnapshotRuntimePreconditionTests passed after 0.001 seconds.
✔ Test run with 3 tests in 1 suite passed after 0.001 seconds.
```

## Findings

### 1. [LOW] Override's async makeViewControllerAsync forwarding is never exercised by these tests

- File: `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/DisplayNameOverrideArtifactTests.swift:65`
- All three tests build fixtures with the SYNC `SnapshotViewGenerator` initializer (`makeValue: (Void) throws -> ...` at `makeLegacyGenerator`, lines 65-79), so `makeViewControllerAsync` is always nil. `__overridingDisplayName` explicitly forwards `makeViewControllerAsync` (SnapshotViewGenerator.swift:100), and that forward is load-bearing: the override fires precisely when a legacy `@SnapshotSuite` has >=2 fallback tests (Test.swift:198), which includes async suites (async init / async `@SnapshotTest` functions produce a generator whose `makeViewControllerAsync` is non-nil per SnapshotViewGenerator.swift:15-18, resolved at assertSnapshot.swift:24). Test 3 (`overrideKeepsLocationAndConfigurationMetadata`, lines 46-63) checks displayName/fileID/filePath/line/column but never asserts `makeViewControllerAsync` survived the wrapper.
- Failure scenario: a legacy `@SnapshotSuite("Some name")` with an async init and two fallback tests `makeFirstView()`/`makeSecondView()` expands to `__overridingDisplayName(of: <async generator>, with: "Some name/makeFirstView")`; if `__overridingDisplayName` is refactored to drop `makeViewControllerAsync`, `resolved.makeViewController(())` hits the sync stub `{ _ in throw SnapshotAsyncMakeValueError() }` and every such async colliding-name test throws at assertion time — yet all three tests here still pass because their generators are sync.
- Suggested fix: add an async-initializer fixture and assert `(async as? SnapshotViewGenerator<Void>)?.makeViewControllerAsync != nil` (and/or resolve it through `assertSnapshot`'s `resolvedSyncViewGenerator`).
- Evidence: Fixture is sync-only: DisplayNameOverrideArtifactTests.swift:65-79 uses `makeValue: { _ in ... }` (sync). The forwarded field it fails to cover: Sources/SnapshotTestingMacros/SnapshotViewGenerator/SnapshotViewGenerator.swift:100 `makeViewControllerAsync: generator.makeViewControllerAsync`. Async path is real: assertSnapshot.swift:24 `guard let makeViewControllerAsync = viewGenerator.makeViewControllerAsync`.

### 2. [IMPROVEMENT] Test 1 only proves pipeline determinism and hard-pins identical names as a required collision

- File: `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/DisplayNameOverrideArtifactTests.swift:19`
- `sharedSuiteDisplayNameCollidesWithoutTheOverride` (lines 18-25) runs `makeLegacyGenerator()` twice with byte-identical inputs and asserts the two artifact-identity sets are equal. Since the generation pipeline is deterministic, `firstArtifacts == secondArtifacts` is tautological — it establishes determinism, not a two-distinct-tests collision, and it never invokes `__overridingDisplayName`. More notably, expressing it as a hard `#expect(==)` pins the contract "two identical display names MUST resolve to the same reference artifact".
- Failure scenario: a future request-generator change that disambiguates identical display names by source location (a reasonable robustness improvement) makes `firstArtifacts` and `secondArtifacts` distinct, failing this test despite the change being an improvement.
- Suggested fix: model the real bug by asserting that two DIFFERENT function fixtures (distinct fileID/line, same suite-fallback display name) still collide, rather than running one generator twice.
- Evidence: DisplayNameOverrideArtifactTests.swift:20-24 — both operands come from `makeLegacyGenerator()` (same displayName "Some name", same filePath, same line/column); the only assertion of substance is `#expect(firstArtifacts == secondArtifacts)`.

### 3. [IMPROVEMENT] Determinism depends on default task-locals and live .minimum AppKit layout instead of scoped traits

- File: `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/DisplayNameOverrideArtifactTests.swift:84`
- Unlike the sibling `AssertionRequestGeneratorTests.makeSingleRequest` (which wraps generation in `SizesSnapshotTrait.$current`/`ThemeSnapshotTrait.$current`/`StrategySnapshotTrait.$current` `withValue` for deterministic, environment-independent output), `artifactIdentities` (lines 81-87) calls `generateRequestsSync()` with no trait scope. It therefore silently depends on: `ThemeSnapshotTrait.current == .all` (so each generator yields 2 requests, keeping the sets non-empty) and `SizesSnapshotTrait.current == [.minimum x .minimum]`, which routes through live AppKit `fittingSize`. The `.minimum` path only stays non-zero because `preserveFrameBasedSize` (SnapshotView+wrappingInContainerView.swift:57-86) pins the 10x10 frame.
- Failure scenario: if someone changes the default of `SizesSnapshotTrait.current` (SizesSnapshotTrait.swift:23) or `ThemeSnapshotTrait.current`, or edits `makeLegacyGenerator`'s frame to `.zero`, this test throws `SizeError.zeroSize` or weakens — for reasons unrelated to display-name override — obscuring the real signal.
- Suggested fix: scope the three traits explicitly around `generateRequestsSync()` like the sibling test does (e.g. `SizesSnapshotTrait.$current.withValue([fixed 10x10])` and `ThemeSnapshotTrait.$current.withValue(.light)`).
- Evidence: DisplayNameOverrideArtifactTests.swift:84 `AssertionRequestGenerator(viewGenerator: generator).generateRequestsSync()` with no `withValue` scoping; contrast `Tests/.../AssertionRequestGeneratorTests.swift:82-88` which scopes all three traits. Non-zero size relies on `Sources/.../SnapshotView+wrappingInContainerView.swift:57-86` pinning frame.size (10x10 at .defaultHigh).

### 4. [IMPROVEMENT] viewController.view != nil is a near-tautology that under-verifies the forwarded closure

- File: `Tests/SnapshotsUnitTests/Assertion/RequestGenerator/DisplayNameOverrideArtifactTests.swift:62`
- In `overrideKeepsLocationAndConfigurationMetadata` (lines 61-62), `resolved.makeViewController(())` runs the forwarded sync closure, which itself sets `controller.view = SnapshotView(frame: 10x10)` (line 71); on AppKit `NSViewController.view` is also auto-created on access. So `#expect(viewController.view != nil)` is effectively always true and proves little about whether the override forwarded the correct closure. The stronger property — that the override preserved the ORIGINAL `makeViewController` rather than substituting a stub — is left unasserted.
- Failure scenario: if `__overridingDisplayName` forwarded a different/stub sync closure returning a bare controller, `viewController.view != nil` would still pass, so this assertion would not catch a corrupted `makeViewController` forward.
- Suggested fix: assert an observable property of the forwarded closure's output, e.g. `#expect(viewController.view.frame.size == CGSize(width: 10, height: 10))`, tying the check to the specific view the original generator builds.
- Evidence: DisplayNameOverrideArtifactTests.swift:61-62; the closure under test sets a non-nil view at line 71. `SnapshotViewController == NSViewController` (UniversalTypes.swift:28), whose `view` is auto-instantiated.
