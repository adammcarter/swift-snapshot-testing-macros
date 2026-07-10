# 01 — GitHub open-issue triage

**Summary.** All 26 open issues assessed against the post-audit code (`HEAD` = `ae20b04`). Three are effectively resolved by the recent audit/fix work and can be closed or verified-and-closed (#18, #23, plus the coverage pair #13/#14 is largely satisfied). Two are external/upstream tracking issues (#97, #40). The remaining bulk splits into a **diagnostics cluster** (#8–#12, #21, #24, #25 — the maintainer's stated priority, mostly still open) and a **features/QoL set** (#1, #2, #16, #17, #26, #28, #45, #64). Detailed designs for the diagnostics and features live in `02-diagnostics-and-warnings.md` and `04-features-and-qol.md`; ADR issues (#6, #7) are expanded in `05-docs-and-onboarding.md`.

## Triage table

| # | Theme | Status | Effort | Value | Recommendation |
|---|---|---|---|---|---|
| 97 | known/external | EXTERNAL (upstream swift-testing #1643) | — | — | Track upstream; our CI already runs 26.4 green. Keep open, link status. |
| 40 | known/external | EXTERNAL (FB17207500) | — | med | Keep open pending Apple; docs already stop requiring `@Suite` conceptually. |
| 64 | bug? | NEEDS-DECISION | M | med | Investigate: reproduce `UITableViewCell` vs `.contentView`; likely a hosting/layout doc note + possible ergonomic overload. |
| 45 | enhancement | STILL-OPEN (good first issue) | S | med | Do it — `Strideable`/`RangeExpression` `configurationValues`. See `04`. |
| 28 | traits | STILL-OPEN | S | med | Do it — `Duration`-based `.timeLimit` seconds helper. See `04`. |
| 26 | enhancement | STILL-OPEN (architectural) | L | high | Explore SwiftUI `ImageRenderer` path (no UIKit/AppKit host). See `04`. |
| 25 | diagnostics/hygiene | STILL-OPEN | M | med | Fold into the diagnostics refactor (`missingValidTests`). See `02`. |
| 24 | diagnostics/bug | STILL-OPEN | S | med | Whitespace/trivia in the annotate-viable-functions fix-it. See `02`. |
| 23 | diagnostics/bug | **ALREADY-DONE** (`c45f3a9`) | — | — | Verify against `testEnumInstanceFunction` fixture and close. |
| 22 | enhancement | STILL-OPEN | S | low | Lazy `IfConfig` properties — minor perf/craft. See `03`. |
| 21 | diagnostics | STILL-OPEN | S | med | Diagnose `throws(E)` typed throws on `@SnapshotTest`. See `02`. |
| 20 | misc | NEEDS-DECISION | M | low | Expand `@SnapshotTest` peer to be visible; UX call. |
| 18 | misc | **ALREADY-DONE** (`94d11b6`, train-3 render) | — | high | mac scale now correct via `AppKitImageRenderer`; close, note the macOS-record caveat. |
| 17 | misc | STILL-OPEN (exploratory) | L | high | `#Preview`↔suite bridge — highest "loveable" upside. See `04`. |
| 16 | traits | STILL-OPEN | M | high | `.record(.deleteStaleReferences)` + loss warning. See `04`. |
| 14 | hygiene | LARGELY-DONE | S | low | Filename logic now has unit tests (`SizesSnapshotTraitSizeNamingTests`, dedup tests); close after a gap check. |
| 13 | hygiene | LARGELY-DONE | S | low | Helper unit coverage added across rounds 2–3; close after a gap check. |
| 12 | diagnostics | STILL-OPEN | M | med | Diagnose function-has-args-but-no-configurations mismatch. See `02`. |
| 11 | diagnostics | STILL-OPEN | S | med | Fix-it: configurations supplied but value not passed to the param. See `02`. |
| 10 | diagnostics | STILL-OPEN | M | med | Per-return-type fix-its for invalid return types (pairs with train-3 warn-and-skip). See `02`. |
| 9 | diagnostics | STILL-OPEN | S | med | Fix-it: invalid `configurations:` → suggest `configurationValues:`. See `02`. |
| 8 | diagnostics | PARTIAL | S | high | Error+fix-it for `@SnapshotTest` outside `@SnapshotSuite` — a `nil`-return path exists but no diagnostic. See `02`. |
| 7 | documentation | STILL-OPEN | M | med | ADR: `@SnapshotTest` opt-in-vs-inference. See `05`. |
| 6 | documentation | STILL-OPEN | L | med | ADR backlog for existing decisions. See `05`. |
| 2 | configurations | STILL-OPEN | M | med | `product`/zip config combinators with explosion guard. See `04`. |
| 1 | configurations | STILL-OPEN | M | med | Result-builder for `configurations`. See `04`. |

## By theme

### Already resolved (verify & close)
- **#23** — "fix-it doesn't play well with trivia in `testEnumInstanceFunction`." Train-3 legacy lane commit `c45f3a9` ("give the *Make function static* fix-it correct trivia") reworked exactly this fix-it's leading/trailing trivia and re-recorded the affected `LegacyHardening` fixtures. Confirm the `testEnumInstanceFunction` expectation is now well-formed and close.
- **#18** — "render mac screenshots with correct scale, then run integration on Mac." Train-2 `T4` + train-3 render lane give `AppKitImageRenderer` an offscreen-window render at `size × displayScale` with the theme appearance. Scale is correct. The "run integration on Mac" half is constrained by the macOS-record caveat (references are recorded on the CI runner; local macOS 27 differs) — document that rather than reopen.
- **#13 / #14** — helper + filename unit coverage. Rounds 2–3 added `SizesSnapshotTraitSizeNamingTests`, the dedup/collision tests, `SnapshotCaseDiscriminatorNamingTests`, migration unit suites, etc. Do a quick gap scan for any still-integration-only helper, then close.

### External / upstream (keep open, annotate)
- **#97** (Xcode 26.4 regression) tracks swiftlang/swift-testing#1643; our matrix runs 26.4 green, so this is upstream-only now.
- **#40** (`@Suite` no longer needed for diamonds) tracks FB17207500.

### Diagnostics cluster (maintainer priority — mostly open)
#8, #9, #10, #11, #12, #21, #24, #25. These are the legacy-macro diagnostic gaps and are the highest-leverage "surface failures to users" work. #8 has a partial `nil`-return path but emits no diagnostic. Full catalogue with messages/fix-its and effort in `02-diagnostics-and-warnings.md`.

### Features / configurations / QoL
#1, #2 (config builder + combinators), #16 (delete-stale-references), #17 (`#Preview` bridge), #26 (vanilla SwiftUI), #28 (`Duration` time-limit), #45 (`Strideable` values), #64 (`UITableViewCell`). Designs in `04-features-and-qol.md`.

### Docs / ADRs
#6, #7 in `05-docs-and-onboarding.md`.

## "Close now" list
- **#23** (fixed by `c45f3a9`) — verify fixture, close.
- **#18** (fixed by `94d11b6` + render lane) — close with the macOS-record note.
- **#13 / #14** — close after a gap scan (coverage now substantial).

## Top candidates (do next, by value/effort)
1. **#8** — error+fix-it for `@SnapshotTest` outside `@SnapshotSuite` (high value, S; a silent no-op today).
2. **#16** — `.record` stale-reference cleanup with an explicit data-loss warning (high value, M; recurring real pain after renames — the whole reference-rename saga in this repo is the motivating example).
3. **#28** + **#45** — two good-first-issue-sized wins (`Duration` time limits, `Strideable` values).
4. **#10** — per-return-type fix-its, pairing with the train-3 warn-and-skip so the message is actionable.
5. **#17** — `#Preview`↔suite bridge: the single most "loveable" feature; exploratory but high ceiling.
