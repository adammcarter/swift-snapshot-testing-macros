# Value & Feature Audit — snapshot-helpers

A forward-looking audit of where the library can add the most value: open-issue triage, the
warnings/failures worth surfacing to users, Swift modernization, features and loveable QoL, and
documentation. Written against `snapshot-helpers` after the correctness audit + fix trains
landed (commit range `f5d0037..7460647`); it assumes the code is correct and asks *what next*.

This is planning material, not code changes. It lives on the `value-audit` branch, separate from
the feature branch.

## The five documents

| Doc | Scope | Headline |
| --- | --- | --- |
| [01 — GitHub issue triage](01-github-issue-triage.md) | All 26 open issues assessed against current code | Several diagnostics/known-issue tickets are already resolved by the recent trains and closeable; the live work is a diagnostics cluster and a features set |
| [02 — Diagnostics & warnings](02-diagnostics-and-warnings.md) | The warnings/errors/fix-its to surface | Turn the remaining **silent-wrongness** cases loud: `@SnapshotTest` outside a suite, config/argument mismatches, typed-throws misuse |
| [03 — Swift modernization](03-swift-modernization.md) | `@TaskLocal`, `@unchecked Sendable`, reflection, macros, modern APIs | Consolidate six trait task-locals into one structured value; replace the private-`_kind` reflection with a durable path; `Mutex` sweep of the boxes |
| [04 — Features & QoL](04-features-and-qol.md) | Polish + loveable net-new | `precision`/`perceptualPrecision` and a customizable timeout are the cheap high-value wins; the `#Preview` bridge is the loveability bet |
| [05 — Docs & onboarding](05-docs-and-onboarding.md) | Doc accuracy, DocC, ADR backlog | The record/CI-recording workflow is undocumented; 25 public overloads have no DocC; ADR backlog answers #6/#7 |

## Cross-cutting themes

1. **Make silent wrongness loud.** The single most-requested and highest-leverage direction
   across issues #8–#12/#21/#24/#25 and doc 02: today several user mistakes produce an empty or
   cryptic result instead of a clear diagnostic. This is the maintainer's stated priority.
2. **Kill cross-machine flakiness.** `perceptualPrecision` (doc 04) plus documenting the
   CI-is-the-recording-environment reality (doc 05) directly address the reference-fidelity pain
   this repo lived through during its own rebaseline.
3. **One durable fix for the reflection hack.** The per-case discriminator relies on reflecting
   Swift Testing's private `Test.Case` layout (docs 03 + the round-3 findings). A matrix canary
   test plus an SPI/value-carrying path should be scheduled before it bites a future toolchain.
4. **The `#Preview` bridge is the adoption bet.** Doc 04's highest-ceiling item (#17): one view,
   both an Xcode canvas preview and a snapshot test.

## Suggested first slice (highest value / lowest cost)

- `precision` / `perceptualPrecision` traits — S, directly fixes the flakiness class.
- Customizable timeout replacing the 5s hardcode — S/M, removes a standing `#warning`.
- The "silent wrongness → diagnostic" batch from doc 02 — mixed S/M, the maintainer's priority.
- Failed-snapshot `Attachment`s in the Swift Testing report — M, big everyday-QoL uplift.
- Close the already-resolved issues listed in doc 01.
