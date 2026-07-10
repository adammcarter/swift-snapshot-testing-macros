# 05 — Documentation, ADRs & onboarding (deep)

**Summary.** The prose docs (README 108 lines, MIGRATION 250, Usage 169, Traits 116,
Parameterised 73 — ~716 lines) are, after the recent refactor trains, **substantially more
accurate than the lighter baseline credited them for** — the migration semantics, `.record`
divergence, slash-name/subfolder behaviour, fixed-size name components, and macOS rendering
semantics are all documented and match the code. The baseline's headline claim — *"zero
symbol/DocC documentation on the public API"* — is **false and should be retired**: every
trait factory (`.theme`, `.sizes`, `.padding`, `.backgroundColor`, `.strategy`, `.record`,
`.diffTool`), `SnapshotConfiguration`, and the legacy `@SnapshotTest`/`@SnapshotSuite` macros
carry real `///` DocC comments with examples. The genuine gaps are narrower and sharper:

1. **The `#expectSnapshot` macro — the single most-used symbol — has zero doc comments**
   across all 25 overloads (`ExpectSnapshotMacroDefinition.swift`), and the runtime funcs it
   forwards to are deliberately DocC-hidden. Quick Help on `#expectSnapshot` shows nothing.
2. **No DocC catalog and no rendered/hosted documentation** — the five `.md` files are
   GitHub-only prose, not a navigable DocC site; nothing ties symbols to the guides.
3. **The entire record/rebaseline workflow is undocumented** — including the load-bearing
   operational fact that *CI is the reference-recording environment of record* and that local
   machines (macOS 27) render differently from the CI runner (macOS 26 / Xcode 26.3).
4. **No ADR trail** (`docs/ADRs/` does not exist) despite issues #6 and #7 explicitly asking
   for one, and despite the audit trains producing a large set of expensive, non-obvious,
   re-litigable decisions.

None of this blocks a user who copies the quick-start, but it blocks *confident* adoption
(Quick Help is empty on the core macro) and *contribution* (a contributor who edits a view
and pushes will hit reference mismatches with no doc explaining why or how to rebaseline).

---

## 1 · Doc-accuracy findings (fix in place)

Severity: **High** = actively misleads or blocks; **Med** = stale/incomplete on a real
surface; **Low** = polish. All line refs are current as of this audit.

| # | Finding | Location | Sev |
|---|---------|----------|-----|
| A1 | **Record/CI-recording workflow entirely absent from docs.** `.github/workflows/record-snapshots.yaml` (the `record/**` push trigger, the delete→record→verify→upload dance, the macos-26 / Xcode 26.3 runner) is documented only in the workflow's own header comment. The load-bearing fact — *references must be recorded on the CI runner because font metrics / display scale / UIKit dump formats differ between machines* — appears in that comment (`record-snapshots.yaml:5-10`) and **nowhere a user or contributor will look**. This is the #1 operational gap. | README, CONTRIBUTING, Documentation/ (all silent) | **High** |
| A2 | **`#expectSnapshot` macro overloads carry no doc comments.** All 25 `public macro expectSnapshot` decls have zero `///`. Quick Help / DocC render nothing for the core API. (Contrast: the legacy `SnapshotTest`/`SnapshotSuite` macros have 300+ lines of `///`.) | `Sources/SnapshotTestingMacros/MacroDefinitions/ExpectSnapshotMacroDefinition.swift:1-175` | **High** |
| A3 | **Toolchain / platform support matrix unstated.** CI builds across Xcode 16.3, 16.4, 26.0, 26.1, 26.2, 26.3 (macos-15) plus 26.4, 26.5 (macos-26) — `run-tests.yaml:37-43` — but no doc states the supported Xcode range. README says only "iOS 15+ and macOS 15+" (correct vs `Package.swift:9-10`, `.macOS(.v15)`/`.iOS(.v15)`), which is the *deployment* floor, not the *toolchain* matrix. Open issue #97 ("Regression in Xcode 26.4") shows the matrix matters to users. | README §Supported platforms; `run-tests.yaml:37` | **Med** |
| A4 | **Local-vs-CI rendering reality undocumented for contributors.** CONTRIBUTING (56 lines) says integration tests "require a specific simulator (iPhone 17, iOS 26.2) to match reference snapshots" (`CONTRIBUTING.md:35`) but never explains that macOS unit references are runner-recorded, that a local macOS 27 machine renders differently from CI's macOS 26, or how to rebaseline. A contributor who edits a snapshotted view has no documented path forward. | CONTRIBUTING.md (whole file) | **High** |
| A5 | **`Tools/remove-snapshots` is undocumented.** The repo ships five `Tools/` scripts; `remove-snapshots` is referenced in no doc (`README`, `CONTRIBUTING`, `MIGRATION`, `Documentation/` all silent). Its role in the rebaseline flow is invisible. | Tools/remove-snapshots | **Med** |
| A6 | **CONTRIBUTING mislabels `mise run lint`.** `CONTRIBUTING.md:53` presents `mise run lint` as equivalent to `./Tools/format-check`, but the `lint` task actually runs `./Tools/format-check` **and** `./Tools/check-packages` (`mise.toml`), so the two are not interchangeable. Minor but a contributor relying on the parenthetical will skip the package check. | CONTRIBUTING.md:53; mise.toml | **Low** |
| A7 | **Test-target map is undocumented.** `Tests/` has SnapshotsUnitTests, SnapshotsIntegrationTests, SnapshotsIntegrationRepetitionTests, SnapshotsPlayground, SnapshotTestSupport plus three `.xctestplan`s. README lists `--filter` unit suites and the two `xcodebuild` schemes but never explains the target taxonomy (unit vs integration vs repetition vs playground) or which one owns which references. | README §Development; CONTRIBUTING | **Med** |
| A8 | **AppKit / macOS-native rendering path under-surfaced.** The macOS image strategy (offscreen re-hosting, sRGB draw, scale semantics, no `WKWebView` special-case) is genuinely documented at `Documentation/Usage.md:153-166` — good — but it is buried under "UIKit and AppKit direct values" and not linked from README's "Supported native surface" table (which lists AppKit but says nothing about its distinct rendering model). The new `AppKitImageRenderer` is a real subsystem; a reader scanning README won't discover the semantics doc. | README:40-45; Usage.md:153 | **Low** |
| A9 | **`.record(false)` divergence is documented twice, consistently — verify it stays so.** `Traits.md:72-76` and `MIGRATION.md:25-30` both correctly state `.record(false)` → `.never` (diverging from pointfree's `false`==`.missing`). Matches `RecordSnapshotTrait+Init.swift:30-51`. **No fix needed — flagged as a correctness anchor to protect in future edits** (it's the kind of subtle claim that rots silently). | Traits.md:72; MIGRATION.md:25 | Low (anchor) |
| A10 | **Repeated-assertion `.N` naming & attempt-token scoping is documented but not attributed to its mechanism.** `Usage.md:44-61` accurately describes per-run `.1` restart and shared naming scope across helpers/child tasks — this matches the new `SnapshotAttemptToken` / per-case execution-context work — but the doc presents it as a naming convention with no pointer to *why* it's safe under parallel/repetition (the token model). Fine for users; a contributor debugging naming needs the mechanism doc (see ADR-3). | Usage.md:44 | Low |

**What is accurate (protect, don't rewrite):** the migration quick-mapping table, the
`argument:` vs explicit-`SnapshotConfiguration` naming-parity guidance
(`MIGRATION.md:116-175`), the full CLI flag/exit-code tables (`MIGRATION.md:188-235` — verified
against `MigrationOptions*.swift` and the staging/atomic-replace model), the slash-name
subfolder rule, and the fixed-size name-component table (`Traits.md:38-64`). These were
round-2 verified and remain correct.

---

## 2 · Documentation roadmap

Ordered by value-per-effort. Effort: **S** ≈ hours, **M** ≈ 1–2 days, **L** ≈ multi-day.

### 2.1 — "Recording & rebaselining references" guide  (**S**, value: High)
The highest-leverage single doc. Covers: why CI is the reference environment of record
(rendering divergence), the `record/**` branch trigger and `workflow_dispatch`, the
delete→record→verify→upload flow, downloading the artifact and committing it, the
`Tools/remove-snapshots` helper, and the `SNAPSHOT_TESTING_RECORD=all` local escape hatch
(already noted in `Traits.md:66-70`). Fixes A1, A4, A5. Put it in `Documentation/Recording.md`
and link from README + CONTRIBUTING.

### 2.2 — Doc comments on `#expectSnapshot` + a DocC catalog  (**M**, value: High)
Fixes A2 + gap 1/2. Two parts:
- **Symbol docs:** add `///` to the `#expectSnapshot` macro decls. The 25 overloads collapse
  into ~6 documentable *shapes* (direct SwiftUI value; direct `SnapshotView`/`ViewController`;
  closure sync/throws/async; `argument:`; `SnapshotConfiguration`; tuple-2/3). Document one
  canonical `///` per shape (params: `named:`, naming behaviour, platform notes, effect
  flavour) — you do not need 25 separate blocks.
- **DocC catalog:** add `SnapshotTestingMacros.docc` with a landing article, and fold the
  existing five `.md` guides in as DocC articles so symbols and prose cross-link. Requires
  adding `swift-docc-plugin` (greenfield — none present today). Enables Quick Help + a hostable
  site.

### 2.3 — Landing/tutorial + troubleshooting FAQ  (**M**, value: High)
- **"Your first snapshot" tutorial** — the happy path from `import` to first recorded
  reference, including the record-then-verify loop.
- **Troubleshooting/FAQ** for the failures users actually hit:
  - *Missing reference* → record once, re-run (and where the file lands).
  - *Cross-machine mismatch* → record on CI / the runner; explain the rendering-divergence
    root cause (ties to 2.1).
  - *"My `#expectSnapshot` test did nothing"* → the runtime-precondition path: it must run on
    the Swift Testing task; from XCTest / `Task.detached` / GCD it is skipped with a run-level
    issue (`MIGRATION.md:19-24` documents the *rule* but there's no FAQ entry keyed on the
    symptom).
  - *Parameterised cases sharing one file / colliding names* → naming + the collision guard.
  - *Zero-size render fails* → the frame-based sizing-error behaviour (`Usage.md:147-149`).

### 2.4 — Toolchain/platform matrix note  (**S**, value: Med)
Fixes A3. A short README/CONTRIBUTING table: supported Xcode versions (16.3→26.5), the two
runner OSes (macos-15 / macos-26), the integration simulator pin (iPhone 17 / iOS 26.2), and
the recording toolchain (Xcode 26.3). Link open issue #97 as the reason this is worth stating.

### 2.5 — CONTRIBUTING depth  (**S**, value: Med)
Fixes A6, A7. Add the test-target map (unit/integration/repetition/playground/support + the
three `.xctestplan`s), the record workflow link, the correct `mise run lint` scope, and the
local-vs-CI rendering caveat.

### 2.6 — Trait reference completeness pass  (**S**, value: Low)
`Traits.md` is already strong. One pass to confirm every public factory in
`Sources/.../Traits/` appears (e.g. `.padding(.horizontal, 12)` edge forms, `.diffTool`
variants, the `DeviceSizingOption` set) and that recursive-suite scoping is mentioned. Low
priority — this is polish, not a gap.

---

## 3 · ADR backlog (prioritized)

No ADR convention exists. **Recommendation:** adopt `docs/ADRs/000-title.md` with the
installed `writing-adrs` skill's status/context/decision/consequences format. Write in the
order below — issues #6/#7 first (they were asked for), then the durable audit-derived
decisions while the reasoning is fresh. Each ADR is **S**; the backlog is **L** in aggregate.

Issue context (verified):
- **#6** ("Write up ADRs for reasoning behind existing ideas") — empty body; a *meta*
  request to capture the existing decision set. Satisfied by writing the ADR-2…ADR-8 set below.
- **#7** ("ADR for @SnapshotTest") — a real design question: legacy `@SnapshotTest` inference
  auto-marks helper functions that return valid views; the issue argues for an **opt-in**
  model (matching Swift Testing's opt-in mental model) vs the current inference, weighing
  discoverability against less-code. Needs a decision recorded, not just a description.

| # | ADR (one-line scope) | Source | Priority |
|---|----------------------|--------|----------|
| ADR-1 | **`@SnapshotTest` inference vs opt-in** — record the opt-in-vs-infer decision for helper-returning-view marking, the discoverability/mental-model tradeoff, and the chosen model (or "Proposed" if undecided). | issue #7 | **1** |
| ADR-2 | **Native `#expectSnapshot`/`@Suite`/`@Test` supersedes legacy `@SnapshotSuite`/`@SnapshotTest`** — why the native surface is preferred, the deprecation (not removal) path, and the warn-and-skip / hardened-diagnostic behaviour for rejected legacy shapes (`MIGRATION.md:175`). | refactor trains, #6 | **2** |
| ADR-3 | **Per-attempt execution-context scoping** — `SnapshotAttemptToken` + per-test-case binding + `isRecursive`; why task-pointer keying was wrong; how it makes `.N` naming deterministic under parallel/repetition. | train-1/3 | **3** |
| ADR-4 | **CI is the reference-recording environment of record** — references recorded on the runner (macos-26 / Xcode 26.3 / iPhone 17·iOS 26.2), not locally, because rendering diverges; the `record/**` workflow is the sanctioned path. | reference saga | **3** |
| ADR-5 | **Reference-naming & collision model** — attempt-scoped `.N` counter, sanitized/lossy normalization, per-case discriminator, and the `SnapshotConfigurationNameCollisions` guard (skip-don't-corrupt on collision). The discriminator bypass found in round 3 is fixed at `7460647`; record the invariant so it cannot regress. | naming audits, round3 | **4** |
| ADR-6 | **Swift Testing case-identity compatibility seam** — replace private `Test.Case._kind` reflection with the compiler-gated `ForToolsIntegrationOnly` arguments SPI across Swift 6.1/6.2, retain a matrix canary, and track the public-API path. Record the SPI/compatibility trade-off rather than canonizing the avoidable reflection hack. | modernization audit, round3 | **4** |
| ADR-7 | **`.record(false)` == `.never` divergence from pointfree** — the deliberate semantic split from `assertSnapshot(record: false)`==`.missing`; why strict-verify was chosen as the Bool mapping. | traits audit | **5** |
| ADR-8 | **Migration-CLI safety model** — dry-run default, atomic replace + `flock` apply lock + private `0700` staging + skip-don't-corrupt, and the exit-code ladder (0–4) as a stable contract. | migration trains | **5** |
| ADR-9 | **macOS/AppKit rendering model** — offscreen re-host per request, sRGB draw, 1pt-per-px default scale (no screen-backing inheritance, for cross-machine reference stability), no `WKWebView` special-case. | AppKit render work | **5** |

---

## 4 · Sequencing (do in this order)

1. **Recording/rebaseline guide + toolchain-matrix note** (2.1 + 2.4, both **S**) — unblocks
   contributors immediately; kills the highest-severity gaps (A1, A3, A4, A5).
2. **ADR-1 (#7) + ADR-2…ADR-4 (#6 core set)** (**S each**) — capture the load-bearing,
   most-re-litigable decisions before the reasoning fades.
3. **`#expectSnapshot` doc comments + DocC catalog** (2.2, **M**) — biggest discoverability
   win; makes Quick Help non-empty on the core macro.
4. **Tutorial + troubleshooting FAQ** (2.3, **M**) + remaining ADRs (5–9).
5. **CONTRIBUTING depth + trait-reference pass** (2.5 + 2.6, **S**) — cleanup tail.

**Correction vs baseline:** the baseline scored the whole public surface as having "zero
symbol documentation" and rated the DocC task **M/high** on that basis. In fact traits,
`SnapshotConfiguration`, and the legacy macros are already well-doc-commented — the DocC task
is smaller and more targeted (the `#expectSnapshot` macro + a catalog to host what exists),
and the record-workflow/ADR gaps are the higher-value work.
