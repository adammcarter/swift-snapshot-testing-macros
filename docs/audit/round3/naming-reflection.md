# Audit round 3: naming-reflection

## Resolution

Resolved on `snapshot-helpers` by removing `SnapshotCaseDiscriminator` and all reflection of
Swift Testing's private `Test.Case._kind` layout. Dynamic compilation against the Apple-shipped
Testing module confirmed that neither `Test.Case.arguments` nor `Test.Case.Snapshot` is exposed,
including under the upstream SPI import names. The supported contract is therefore fail-closed:
a bare assertion in a parameterised case records an actionable issue and does not render;
`argument:` and `SnapshotConfiguration` provide case identity, while `named:` may only label an
assertion whose case identity is already configured.

This removes both findings at their shared root. There is no lossy inferred discriminator left to
collide, and a toolchain layout change can no longer silently disable case identity.

---

Focused follow-up on the TRAIN-3 parameterized-case naming fix (commit 6ba1ccf) in the
naming-reflection lane. The per-case discriminator work correctly disambiguates most
parameterized cases, and its determinism, tuple handling, and configuration-suppression
paths are consistent with the existing `argument:` derivation. Two defects remain: one
MEDIUM incomplete-fix that reintroduces an unguarded subclass of the exact silent
reference-file collision the project already guards elsewhere, and one LOW silent-no-op
that can reinstate the round-2 overwrite bug on toolchains outside the CI matrix. Findings
below are ordered by severity.

---

## MEDIUM — Discriminator path reintroduces lossy-normalization collisions unguarded by `SnapshotConfigurationNameCollisions`

- **File:** `Sources/SnapshotTestingMacros/Assertion/SnapshotExecutionContext.swift:44`

**Failure scenario.** Two parameterized cases whose argument values normalize identically
under `\W+`-collapsing — e.g. `"v1.0"` and `"v1 0"`, both folding to `"v1-0"` — silently
share one reference file. The first case writes/records `<baseName>-v1-0`; the second
resolves the identical name and cross-compares against (or overwrites) the first case's
reference, with no diagnostic and no test issue.

**Evidence.** The fix derives a per-case discriminator from argument values through the same
lossy pipeline as the `argument:` path — `String(describing:)` folded through
`SnapshotNameNormalizer.folderComponent` (`SnapshotCaseDiscriminator.swift:41-55`,
`DerivedSnapshotNames.swift:2-3`) — and folds it into the unnamed reference name as
`"\(baseName)-\(caseDiscriminator)"` (`SnapshotExecutionContext.swift:44-45`). The
`argument:` path routes every derived name through
`SnapshotConfigurationNameCollisions.shared.conflictingValueDescription`
(`ExpectSnapshotAdapter.swift:765-793`), recording a test Issue and skipping the assertion
when two distinct values normalize to one name. The new discriminator path invokes no such
guard — `SnapshotConfigurationNameCollisions` is only reached from `resolvedConfiguration`
(the `argument:` path). Because each case runs in its own attempt/context, the per-context
`usedNames` dedupe cannot catch a cross-case collision. `folderComponent("v1.0") ==
folderComponent("v1 0") == "v1-0"` (`SnapshotNameNormalizer.swift:4-8`). The new test file
has no coverage for this case. This is an incomplete fix (not a regression from pre-fix
behavior), but it reintroduces the precise harm `SnapshotConfigurationNameCollisions.swift:1-23`
was built to prevent — its own doc cites the `"v1.0"` vs `"v1 0"` -> `"v1-0"` example.

**Suggested fix.** Route the folded unnamed discriminator name through
`SnapshotConfigurationNameCollisions` the same way `resolvedConfiguration` does (register the
raw value description keyed by call site + occurrence + resolved name; record an Issue and
skip when a different value already resolved that name), or at minimum surface a warning when
two distinct case discriminators normalize identically within one test.

---

## LOW — Case-identity reflection silently no-ops (reintroducing the round-2 collision) on any toolchain whose `Test.Case._kind` layout differs

- **File:** `Sources/SnapshotTestingMacros/Assertion/SnapshotCaseDiscriminator.swift:65`
- **needs_dynamic_verification:** yes

**Failure scenario.** On any toolchain in the CI matrix (Xcode 16.3 -> 26.5, spanning
multiple swift-testing versions) or on a consumer toolchain not covered by CI where the
reflected private layout differs, `argumentValues` returns nil, the discriminator becomes
nil, and every parameterized case again resolves the identical undiscriminated base name —
silently reinstating the exact round-2 reference-overwrite bug this commit fixed, with no
crash and no diagnostic.

**Evidence.** `argumentValues` walks swift-testing's private `Test.Case._kind` enum,
expecting a `.parameterized` case whose payload has an `arguments` label with elements
exposing a `value` label (`SnapshotCaseDiscriminator.swift:65-107`). Any failed private-layout
assumption degrades to nil, which `SnapshotAttemptToken.swift:69` passes as
`caseDiscriminator`, disabling disambiguation. The only guard is the CI unit test
`extractorDerivesDiscriminatorFromParameterizedCase`
(`SnapshotCaseDiscriminatorNamingTests.swift:81-86`), which would fail (catching a layout
break at build time) only IF it runs on that toolchain — so the CI matrix is partially
guarded and consumer toolchains outside CI are not. There is no runtime signal distinguishing
'genuinely non-parameterized' (correct nil) from 'parameterized but shape unreadable' (silent
regression).

**Suggested fix.** Emit a one-time debug warning (or test-only Issue) when a case is detected
as parameterized-by-other-signal but the reflection yields nil, so a silent no-op on an
unguarded toolchain is observable rather than a silent reference collision. Pin/verify the
reflected shape against each swift-testing version in the CI matrix.
