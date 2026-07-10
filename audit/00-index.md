# Value & Feature Audit — snapshot-helpers

A forward-looking audit of where the library can add the most value: open-issue triage, the
warnings/failures worth surfacing to users, Swift modernization, features and loveable QoL, and
documentation. Written against `snapshot-helpers` after the correctness audit + fix trains
landed (commit range `f5d0037..7460647`); it verifies the remaining gaps and asks *what next*.

This is planning material, not code changes. It lives on the `value-audit` branch, separate from
the feature branch.

## The five documents

| Doc | Scope | Headline |
| --- | --- | --- |
| [01 — GitHub issue triage](01-github-issue-triage.md) | All 26 open issues assessed against current code | Several diagnostics/known-issue tickets are already resolved by the recent trains and closeable; the live work is a diagnostics cluster and a features set |
| [02 — Diagnostics & warnings](02-diagnostics-and-warnings.md) | The warnings/errors/fix-its to surface | Turn the remaining **silent-wrongness** cases loud: `@SnapshotTest` outside a suite, config/argument mismatches, typed-throws misuse |
| [03 — Swift modernization](03-swift-modernization.md) | `@TaskLocal`, `@unchecked Sendable`, case identity, macros, modern APIs | Replace avoidable private-`_kind` reflection with the existing compiler-gated Testing SPI; fix trait-less multi-assertion naming; modernize only the boxes whose state can become checked |
| [04 — Features & QoL](04-features-and-qol.md) | Polish + loveable net-new | `precision`/`perceptualPrecision` and a customizable snapshot timeout are cheap high-value wins; a native scenario/catalog macro is the credible `#Preview` bridge |
| [05 — Docs & onboarding](05-docs-and-onboarding.md) | Doc accuracy, DocC, ADR backlog | The record/CI-recording workflow is undocumented; 25 public overloads have no DocC; ADR backlog answers #6/#7 |

## Cross-cutting themes

1. **Make silent wrongness loud.** The single most-requested and highest-leverage direction
   across issues #8–#12/#21/#24/#25 and doc 02: today several user mistakes produce an empty or
   cryptic result instead of a clear diagnostic. This is the maintainer's stated priority.
2. **Reduce cross-machine flakiness.** `perceptualPrecision` (doc 04) plus documenting the
   CI-is-the-recording-environment reality (doc 05) directly address the reference-fidelity pain
   this repo lived through during its own rebaseline.
3. **Remove the reflection hack.** Supported Swift Testing lines already expose case arguments
   through SPI; use a Swift-6.1/6.2-gated adapter and run its canary on every matrix row so a toolchain
   change fails at compile/test time rather than silently sharing references.
4. **The native `#Preview` bridge is the adoption bet.** Doc 04's highest-ceiling item (#17): a new
   scenario/catalog surface feeds both an Xcode canvas preview and native snapshot tests without
   adding flagship behaviour to deprecated `@SnapshotSuite`.

## Suggested first slice (highest value / lowest cost)

- The "silent wrongness → diagnostic" batch from doc 02 — mixed S/M, the maintainer's priority.
- Replace `Test.Case` reflection with the compiler-gated SPI adapter + matrix canary — S.
- Pin and fix trait-less multi-assertion reference collisions — S/M, current correctness gap.
- `precision` / `perceptualPrecision` traits — S, directly reduces the flakiness class.
- Customizable snapshot timeout replacing the 5s hardcode — S/M, removes a standing `#warning`.
- Failed-snapshot `Attachment`s in the Swift Testing report — M, big everyday-QoL uplift.
- Close the already-resolved issues listed in doc 01.
