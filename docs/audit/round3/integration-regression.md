# Audit round 3: integration-regression

Reviewed the cross-lane integration of the merged train-3 fixes (4454fc9..ae20b04),
focusing on how the naming lane's `provideScope`/`testCase` signature change composes
with the legacy trait boxes and the render pipeline. The signature change is clean:
both `SnapshotTestScoping`'s default `provideScope(for:testCase:performing:)` and
`__TestScopingBox` were updated to pass `for: testCase`, the public
`provideScope(performing:)` protocol requirement is unchanged, and every trait
conformer routes through the updated default — no compile break or shared-context
leak. One genuine gap survives: the new per-case discriminator naming path (6ba1ccf)
folds lossy-normalized argument values into unnamed reference names but, unlike the
sibling `argument:`/configuration path, never consults the cross-case
`SnapshotConfigurationNameCollisions` guard, so two parameterized cases whose argument
descriptions differ only by punctuation silently share one reference file. Plus one
efficiency note: the AppKit renderable pre-flight allocates the full render bitmap
twice per image assertion. No tracked files modified; no builds/tests run beyond the
pre-push runtime-precondition gate.

---

## Finding 1 — New per-case discriminator naming path (6ba1ccf) skips the cross-case lossy-normalization collision guard

- **Severity:** medium
- **File:** `Sources/SnapshotTestingMacros/Assertion/SnapshotCaseDiscriminator.swift:28`
- **Also touches:** `SnapshotNameNormalizer.swift:4-8`, `SnapshotExecutionContext.swift:44-45`,
  `ExpectSnapshotAdapter.swift:1112-1114` (set) and `762-796` (sibling guard),
  `SnapshotAttemptToken.swift:65-72`

**Failure scenario**

`@Test(arguments: ["a.b", "a/b"]) func f(s: String) { #expectSnapshot(of: MyView(s)) }`.
Case 1 discriminator = `folderComponent("a.b")` = `a-b`; case 2 =
`folderComponent("a/b")` = `a-b`. Every parameterized case runs under a fresh
`SnapshotAttemptToken`/`SnapshotExecutionContext`
(`SnapshotAttemptToken.withAttemptScope` binds a new token when `current == nil`), so
the per-context `usedNames` dedupe cannot see the other case. Both cases resolve
display name `f-a-b` and reference id `1`, writing/reading a single reference file. One
case's render silently overwrites or is compared against the other case's reference;
the suite passes with false confidence.

**Evidence**

6ba1ccf added a per-case discriminator so an unnamed, non-`argument:`
`#expectSnapshot` inside a parameterized `@Test(arguments:)` folds the case's argument
value(s) into the reference name (`<fn>-<discriminator>`). The discriminator joins
`SnapshotNameNormalizer.folderComponent(...)` of each argument
(`SnapshotCaseDiscriminator.swift:28-34`), and `folderComponent` collapses every
`\W+` run to `-` (`SnapshotNameNormalizer.swift:4-8`). It is folded into the name at
`SnapshotExecutionContext.swift:44-45` whenever `disambiguatesUnnamedCase` is true,
which `ExpectSnapshotAdapter.swift:1112-1114` sets to `configuration.name == nil`. The
sibling `argument:`/configuration path derives its name then consults the process-wide
`SnapshotConfigurationNameCollisions.shared` guard, recording an Issue and skipping
when two cases fold to one name (`ExpectSnapshotAdapter.swift:762-796`). The new
discriminator path performs NO equivalent cross-case check. Before 6ba1ccf all cases
collided (the bug being fixed), so this is an incomplete fix rather than a fresh
regression, but the guard asymmetry is newly introduced and leaves a real residual
silent collision.

**Needs dynamic verification:** yes.

**Suggested fix**

On the unnamed discriminator path, route through the same cross-case collision guard
used for derived configuration names: before folding `caseDiscriminator` into the base
name, register `(callSite, resolvedName, occurrence, full-fidelity argument
description)` with `SnapshotConfigurationNameCollisions.shared` and, on a description
mismatch for an identical normalized name, record an Issue and skip the assertion
instead of overwriting. Alternatively derive the discriminator from a
collision-resistant (non-lossy) encoding of the argument description.

---

## Finding 2 — AppKit renderable pre-flight allocates the full render bitmap twice per image assertion

- **Severity:** improvement
- **File:** `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/AppKitImageRenderer.swift:164`
- **Also touches:** `AppKitImageRenderer.swift:141`, `StrategyAssertionRequestGenerator.swift:54`

**Failure scenario**

For large-but-valid snapshots (e.g. a 6K@3x reference) every legitimate `.image`
request allocates the full-size bitmap once at request-generation time purely to
validate, frees it, then allocates it again at render time — doubling the allocation
work per assertion. Correct and bounded, just wasteful.

**Evidence**

f048908's `validateRenderable(size:displayScale:)` pre-flights by calling `makeBitmap`
and discarding the result (`_ = try makeBitmap(...)`, `AppKitImageRenderer.swift:164-166`).
`NSBitmapImageRep(bitmapDataPlanes: nil, ...)` eagerly allocates the pixel backing, so
validation allocates the full bitmap at `StrategyAssertionRequestGenerator.swift:54`,
frees it, then `drawImage` allocates it again at `AppKitImageRenderer.swift:141`. Two
full-size allocations per legitimate image assertion.

**Needs dynamic verification:** no.

**Suggested fix**

Split validation from allocation: a cheap `validateRenderable` that only checks the
pixel-count / byte-cap arithmetic (`pixelsWide/High >= 1`, `< Int.max`,
`w*h*4 <= cap`) without constructing an `NSBitmapImageRep`, and construct the actual
bitmap only once at render time.
