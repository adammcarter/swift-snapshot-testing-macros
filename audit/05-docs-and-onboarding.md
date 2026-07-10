# 05 — Documentation, ADRs & onboarding

**Summary.** Prose docs (README, MIGRATION, Usage/Traits/Parameterised — 770 lines total) are broadly accurate post-refactor (round-2 verified the migration/usage prose), but they have three structural gaps: **zero symbol/DocC documentation** on the 25 public `#expectSnapshot` overloads, the **entire record/rebaseline workflow is undocumented** (including the load-bearing fact that CI is the reference-recording environment of record), and there is **no ADR trail** (`docs/ADRs/` doesn't exist) despite issues #6 and #7 explicitly asking for one. None of this blocks users who copy the quick-start, but it blocks *confident* adoption and contribution.

## Doc-accuracy findings (fix in place)
- **Record/CI-recording workflow: absent.** Nothing documents `.github/workflows/record-snapshots.yaml`, the `record/**` branch trigger, or — critically — that references must be recorded on the CI runner because local machines (e.g. macOS 27 vs CI's 26) render differently. This is the single most important operational fact a contributor needs and it lives only in commit messages. **Add a "Recording & rebaselining references" doc section. Effort S, value high.**
- **Platform/matrix reality unstated.** The supported Xcode/OS matrix, the iOS-simulator pin (iPhone 17 / iOS 26.2), and the "integration references are simulator/runner artifacts" caveat aren't in the docs. **S.**
- **Trait reference completeness.** `Documentation/Traits.md` (116 lines) should be cross-checked trait-by-trait against the current trait set and the newer behaviors (recursive suite scoping, `.record(false)`==`.never` divergence from pointfree, per-attempt naming). Flag any drift. **S.**
- **Legacy-vs-native framing.** Ensure MIGRATION.md's deprecation story matches the current warn-and-skip / hardened-diagnostic behavior the recent trains landed. **S.**

## Documentation roadmap
1. **DocC symbol docs on the public API (M, high).** The 25 `#expectSnapshot` overloads and every public trait factory have no doc comments. Add DocC comments (params, naming behavior, platform notes, effect-flavor guidance) and a DocC catalog. This is the difference between "discoverable in Xcode Quick Help" and "read the source."
2. **A landing/tutorial + troubleshooting/FAQ (M).** A "your first snapshot" tutorial and a FAQ for the common failures: missing reference (record then re-run), cross-machine mismatch (record on CI / use `perceptualPrecision`), `@SnapshotTest` did nothing (needs `@SnapshotSuite` — #8), parameterized cases sharing a file (naming), zero-size render.
3. **"Recording references" guide (S, high)** — the record workflow, as above.
4. **Contributing depth (S).** CONTRIBUTING.md is 56 lines; add the test-target map (unit vs integration vs repetition vs playground), the record workflow, and the local-vs-CI rendering caveat so contributors don't fight reference mismatches.

## ADR backlog (issues #6, #7)

No ADR convention exists yet. Recommend `docs/ADRs/NNN-title.md` with a lightweight status/context/decision/consequences format. The recent audit generated a rich set of durable, ADR-worthy decisions — capture them while the reasoning is fresh:

| ADR | Scope | Source |
|---|---|---|
| `@SnapshotTest` opt-in vs inference | #7 — helper functions returning views get auto-marked; document the chosen model and the opt-out question | issue #7 |
| Native `@Suite`/`@Test`/`#expectSnapshot` vs legacy macros | why the native surface supersedes `@SnapshotSuite`/`@SnapshotTest`; deprecation path | recent refactor |
| Per-attempt execution-context scoping | `SnapshotAttemptToken` + `isRecursive` per-test-case binding; why task-pointer keying was wrong | train-1/3 |
| CI is the reference-recording environment | why references are recorded on the runner, not locally | reference saga |
| Migration-CLI safety model | atomic replace + flock + staging + skip-don't-corrupt | migration trains |
| `.record(false)` == `.never` divergence from pointfree's `false`==`.missing` | deliberate; document the semantic | traits audit |
| Reference-naming & collision model | attempt-scoped `.N` counter, sanitized dedup, per-case discriminator, collision guard | naming audits |

**Effort:** the backlog is **L** in aggregate but each ADR is **S**; write the two the issues ask for first (#7, then the "existing decisions" set #6), then the audit-derived ones. High value for a project that just made many expensive, non-obvious decisions — without ADRs they'll be re-litigated.

## Sequencing
1. Record/rebaseline guide + platform-matrix note (**S**, unblocks contributors immediately).
2. ADRs #7 and #6 + the top three audit-derived ADRs (**S each**).
3. DocC symbol docs on the public surface (**M**, biggest discoverability win).
4. Tutorial + FAQ (**M**).
