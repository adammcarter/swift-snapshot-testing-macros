# 04 — Features, QoL & loveable capabilities

**Summary.** The trait surface (theme, sizes, padding, backgroundColor, strategy, record, diffTool) is solid; the highest-value work is (a) closing sharp edges users hit repeatedly — a **customizable timeout**, **stale-reference cleanup**, **precision controls** — and (b) one genuinely *loveable* bet: **bridging `#Preview` and snapshot suites** (#17). Below: polish items and net-new "delighters," each with a value rationale, an API sketch, architecture fit, effort, and risk.

## Polish existing features

### Customizable snapshot timeout (from the 5s hardcode)
- **Why:** `Asserter.swift:104` hardcodes `timeout: 5` with a `#warning`. Async view construction or slow CI can spuriously fail; users can't tune it.
- **API:** `.timeout(_ duration: Duration)` trait on `@Suite`/`@Test`, task-local like the others; on timeout the recorded message names the trait.
- **Fit:** identical shape to the existing scalar traits; read in `Asserter`. **Effort S/M. Risk low.**

### `.record(.deleteStaleReferences)` (#16)
- **Why:** after a rename, orphaned reference files linger (this repo lived that pain during its own rebaseline). No supported way to prune.
- **API:** extend `RecordKind`/add a record option that deletes the target `__Snapshots__` subtree before recording, **gated behind a loud warning diagnostic** ("this deletes existing references; data loss if the rename was unintended").
- **Fit:** `RecordSnapshotTrait` + the directory logic already in `AssertionRequestGenerator`. **Effort M. Risk medium** (data loss) → must warn + ideally dry-run list first.

### Expose `precision` / `perceptualPrecision`
- **Why:** pointfree's image strategy supports pixel/perceptual tolerance; cross-machine/font-AA flakiness (the macOS-26-vs-27 saga) is exactly what `perceptualPrecision` solves. Not currently surfaced.
- **API:** `.precision(_:)` / `.perceptualPrecision(_:)` traits threaded into the `.image` strategy.
- **Fit:** `StrategyAssertionRequestGenerator` builds the `Snapshotting`; add the params. **Effort S. Risk low.** High practical value given this repo's reference-fidelity history.

### `Duration` time-limit helper (#28) — **S**
`.timeLimit(.seconds(30))` converting to swift-testing's `.minutes` on the fly. Trait extension only.

### `Strideable`/range `configurationValues` (#45) — **S**, good first issue
Accept `stride(from:to:by:)` and `RangeExpression` where `configurationValues` takes a `Collection`. Overload + tests.

### `UITableViewCell` / `.contentView` ergonomics (#64) — **M**, investigate first
Reproduce whether the wrong snapshot is a hosting/layout issue in the library or client code. If library: document the `.contentView` requirement and consider a cell-aware convenience overload.

### Config combinators (#2) & builder (#1) — **M each**
`product`/`zip` over `configurationValues` (with an explosion guard mirroring swift-testing's guidance), and a result-builder for assembling `configurations`. Design behind the existing `SnapshotConfiguration` type; keep the explosion guard front-and-center.

## Delighters (net-new)

### #Preview ↔ snapshot-suite bridge (#17) — the loveable one
- **Why:** the dream workflow — write the view once, get *both* an Xcode canvas preview and a snapshot test. Today they're separate.
- **Sketch:** `#Preview { MySnapshotSuite.previews }` — generate a `previews` static from the suite's test views so a suite doubles as a preview provider (the issue's own preferred direction: suite → preview, not preview → tests). Explore a `@SnapshotSuite`-generated `PreviewProvider`/`#Preview` peer.
- **Fit:** the macro already enumerates view-producing functions; emitting a preview peer is additive. **Effort L, exploratory. Risk medium** (`#Preview` macro constraints) but the highest ceiling — this is the feature that makes people adopt the library.

### Attach failed snapshots to the Swift Testing report
- **Why:** on failure, the diff currently lives on disk with a path in the message. Swift Testing has `Attachment` — attaching the reference/failure/diff images inline makes failures readable in Xcode and CI report UIs without hunting for files.
- **Sketch:** on mismatch, `Attachment.record(...)` the reference + newly-taken image (+ diff if available).
- **Fit:** the failure path in `Asserter`/`IssueRecordingAsserter`. **Effort M. Risk low.** Big everyday-QoL uplift.

### Stale-reference detection & report (pairs with #16)
- **Why:** even without deleting, telling the user "these N reference files match no current test" turns a silent-rot problem into an actionable list. The migration CLI already has scanner machinery to model this.
- **Sketch:** a `--report-orphans` mode / a test-run summary of unreferenced `__Snapshots__` files.
- **Effort M. Risk low.**

### Vanilla SwiftUI without a UIKit/AppKit host (#26)
- **Why:** currently SwiftUI is converted to UI/NSViews immediately, so a pure-SwiftUI/watchOS-ish path is impossible.
- **Sketch:** a SwiftUI `ImageRenderer`-based strategy (iOS16/macOS13+) for view snapshots that need no host.
- **Fit:** new `Strategy` branch. **Effort L. Risk medium** (fidelity vs the host path; keep both). Unlocks platforms the host path can't reach.

### Auto-record-once ergonomics
- **Why:** first run always fails-then-records; a `.record(.missingOnly)`-style default plus a clear "recorded N new references, re-run to verify" summary smooths onboarding.
- **Effort S.** Mostly messaging on top of the existing `.missing` behavior.

## Prioritized roadmap
1. **Precision/perceptualPrecision** (S, high — directly fixes the cross-machine flakiness class).
2. **Customizable timeout** (S/M, removes a hardcode + `#warning`).
3. **Failed-snapshot attachments** (M, high everyday value).
4. **#28 + #45** (two S good-first wins).
5. **#16 delete-stale + orphan report** (M, high, needs the loss warning).
6. **#17 `#Preview` bridge** (L, exploratory, highest loveability ceiling).
7. **#26 vanilla SwiftUI**, **#1/#2 config builder/combinators**, **#64** — schedule as capacity allows.
