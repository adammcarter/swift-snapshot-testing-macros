# 04 — Features, QoL & loveable capabilities

**Summary.** The trait surface (theme, sizes, padding, backgroundColor, strategy, record, diffTool)
is solid and the `#expectSnapshot` overload matrix is genuinely broad (value/closure/async/throws ×
`argument:`/`SnapshotConfiguration`/tuple-2/tuple-3 × SwiftUI/`SnapshotView`/`SnapshotViewController`).
The highest-value work splits three ways: **(a)** close sharp edges users hit repeatedly — a
**customizable timeout** (a standing `#warning`), **precision / perceptualPrecision** (the exact fix
for the cross-machine flakiness this repo lived), and **stale-reference cleanup** (#16); **(b)** finish
a set of cheap, well-scoped issue requests (#28, #45, #64, #1/#2); and **(c)** make one genuinely
*loveable* bet — **bridging `#Preview` and snapshot suites** (#17). Below: the reusable architecture
spine every trait rides on, an inventory of the current surface, the pointfree capabilities *not* yet
surfaced, then each idea with value rationale, a concrete API sketch (real signatures), the exact files
it touches, effort, and risk/compat.

---

## The trait recipe (the reusable spine)

Almost every "expose one more knob" item below is the same shape. A new scalar trait is five
mechanical wiring points, so effort estimates are dominated by tests + docs, not novel design:

| # | File | What you add |
| --- | --- | --- |
| 1 | `Traits/<X>SnapshotTrait.swift` | `struct XSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping` with `@TaskLocal static var current`, `debugDescription`, and `provideScope { withValue }`. Mirror `StrategySnapshotTrait.swift`. |
| 2 | `Traits/<X>SnapshotTrait+Init.swift` | `.x(...)` factory on `extension Testing.Trait where Self == XSnapshotTrait`. Mirror `ThemeSnapshotTrait+Init.swift`. |
| 3 | `Assertion/ResolvedSnapshotRuntimeState.swift` | Add a stored field, capture it in `static var current`, re-bind it in `withAppliedValues`. **This is the load-bearing step** — it is what carries the value across the adapter's `DispatchQueue.main.sync` hop, where task-locals do not flow. |
| 4 | `Assertion/RequestGenerator/AssertionRequestContext.swift` + `AssertionRequestGenerator.makeContext` | Add to `TraitConfiguration` only if a *request generator* (not the asserter) needs it. |
| 5 | `Assertion/RequestGenerator/Generators/StrategyAssertionRequestGenerator.swift` | Thread it into the `Snapshotting` / `Diffing` (image knobs), or read it in `Asserter.swift` (asserter-level knobs like timeout). |

The `debugDescription` on step 1 matters for loveability: it is what shows up in the failing-test
message (`SnapshotTrait.debugDescription`), so a good default label makes misconfiguration
self-explaining. Because task-locals are bound at the moment `collectSnapshotFailuresSync` runs
(inside `withAppliedValues` on the far side of the hop), asserter-level knobs can be read directly in
`PointfreeAsserter.verifySnapshot` — no need to thread them onto `AssertionRequest` — *provided* they
were captured into `ResolvedSnapshotRuntimeState` first (step 3).

---

## Current feature surface (what exists today)

| Capability | Where | Notes |
| --- | --- | --- |
| Theme (light/dark/all) | `ThemeSnapshotTrait` | Fan-out; applied at render time per artifact. |
| Sizes (`.fixed` / `.minimum`, devices, W×H) | `SizesSnapshotTrait(+Device/+Length/+Size)` | Fan-out. `Length` has a standing `#warning` to split `.minimum` into `.intrinsicContentSize`/`.preferredContentSize`. |
| Padding | `PaddingSnapshotTrait` | Decorator around the hosted view. |
| Background color | `BackgroundColorSnapshotTrait` | Re-applied per render so dynamic colors resolve per theme. |
| Strategy (`.image` / `.recursiveDescription`) | `StrategySnapshotTrait` | Only two strategies surfaced. |
| Record mode | `RecordSnapshotTrait` = pointfree `Record` (`.all/.failed/.missing/.never`) | `nil`-means-inherit semantics preserved; `.record(false)` → `.never` (documented divergence). |
| Diff tool | `DiffToolSnapshotTrait` = pointfree `DiffTool` | `nil`-means-inherit. |
| Swift Testing passthrough traits | `Bug`, `Condition`, `Tag`, `TimeLimit` | `TimeLimitTrait` retro-conformed; minutes-only today (#28). |
| Parameterisation | `SnapshotConfiguration<T>`, `SnapshotConfigurationParser` | Array/closure/`Collection` overloads; derived names with collision detection. |
| Async / throwing builders | `ExpectSnapshotAdapter` cores | `runSync/runSyncThrowing/runAsync/runAsyncThrowing`. |
| Migration CLI | `SnapshotMigrationSupport` | Scanner + rewriter + staging + JSON report — reusable machinery for orphan detection (below). |

---

## Gap: what pointfree exposes that this library does NOT surface

Verified against the vendored checkout `.build/checkouts/swift-snapshot-testing`:

| pointfree capability | Signature (verified) | Surfaced here? |
| --- | --- | --- |
| Pixel tolerance | `Diffing.image(precision: Float = 1, perceptualPrecision: Float = 1, scale:)`; every `.image(...)` factory (`UIViewController`, `NSViewController`, `SwiftUIView`, `UIImage`, `NSImage`, `SceneKit`, `SpriteKit`) takes `precision`/`perceptualPrecision` | **No** — the library calls `.image(size:traits:)` / `.image` with the defaults (`1`), so tolerance is pinned to exact. |
| SwiftUI image layout | `SwiftUISnapshotLayout`: `.device(config:)` (iOS/tvOS), `.fixed(width:height:)`, `.sizeThatFits` | Partly — the library re-hosts and sizes itself; the pointfree layout enum is not exposed. |
| `drawHierarchyInKeyWindow` | `.image(drawHierarchyInKeyWindow: Bool = false, …)` on `UIView`/`UIViewController`/SwiftUI | **No** — needed for true "renders in a host app" fidelity (materials, blur). |
| Timeout | `verifySnapshot(… timeout: TimeInterval = 5, …)` | **No** — hardcoded `timeout: 5` at `Asserter.swift:104` with a `#warning`. |
| Record modes incl. `.failed` | pointfree `Record` has `.all/.failed/.missing/.never` | `.failed` reachable via `.record(.failed)` but undocumented; **no** delete/stale option exists in pointfree either (so #16 is net-new here). |
| Other strategies | `.dump`/`.json`/`.lines` (`Encodable`, `String`, `Any`, `Data`, `URLRequest`, `CALayer`, SceneKit/SpriteKit) | **No** — only `.image`/`.recursiveDescription`. |

Note the timeout type is `TimeInterval` (seconds), not `Duration` — the `.snapshotTimeout(Duration)` trait must
convert, exactly like the #28 `.timeLimit(Duration)` conversion. There is **no** async/`.wait`
snapshotting strategy in this pinned pointfree version; async support is entirely the library's own
(`makeValue` awaited on the test task before the hop).

---

## Polish existing features

### 1. Precision / perceptualPrecision — the cross-machine flakiness fix
- **Why loveable:** this repo's own history is the pitch. Font anti-aliasing, GPU/driver deltas, and
  the macOS-26-vs-27 rebaseline saga are exactly what `perceptualPrecision` was built for. Today every
  comparison is pinned to exact-pixel (`precision: 1`), so a one-pixel AA shift is a red build. A team
  that can set `.perceptualPrecision(0.98)` stops fighting their CI.
- **API:**
  ```swift
  extension Testing.Trait where Self == PrecisionSnapshotTrait {
    public static func precision(_ precision: Float) -> Self
    public static func perceptualPrecision(_ perceptualPrecision: Float) -> Self
    public static func precision(_ precision: Float, perceptualPrecision: Float) -> Self
  }
  // @Suite(.perceptualPrecision(0.98)) / @Test(.precision(0.99))
  ```
- **Fit:** the trait recipe (new `PrecisionSnapshotTrait` carrying `(precision, perceptualPrecision)`,
  default `(1, 1)`). Steps 3–5: capture in `ResolvedSnapshotRuntimeState`, add to
  `TraitConfiguration`, and in `StrategyAssertionRequestGenerator` pass the values into the `.image`
  factory — **UIKit** `.image(precision:perceptualPrecision:size:traits:)` (pointfree overload already
  accepts them) and **AppKit** `makeImageSnapshotting()`'s `Snapshotting<NSImage, NSImage>.image`
  → `.image(precision:perceptualPrecision:)`. `recursiveDescription` ignores it (string diff) — document
  that. **Effort S** (mechanical, ~5 files + tests). **Risk low.** Highest value-per-line item here.

### 2. Customizable snapshot timeout (kill the 5s hardcode + `#warning`)
- **Why:** `Asserter.swift:104` hardcodes `timeout: 5` under a live `#warning`. Async view construction,
  slow CI agents, or a heavy `makeValue` spuriously fail with a timeout the user can't tune.
- **API:** `.snapshotTimeout(_ duration: Duration)` (Swift-native and unambiguous beside Swift
  Testing's time-limit APIs), converted to `TimeInterval` seconds at the
  call to `verifySnapshot`. Default stays 5s. `debugDescription` names the trait so a timeout failure
  says which knob to turn.
- **Fit:** new `TimeoutSnapshotTrait` (recipe steps 1–3). It is an **asserter-level** knob, so no
  `AssertionRequest` change: capture it in `ResolvedSnapshotRuntimeState` (step 3), then read
  `TimeoutSnapshotTrait.current` inside `PointfreeAsserter.verifySnapshot` and pass
  `timeout: duration.timeIntervalValue`. Delete the `#warning`. **Effort S/M. Risk low.**

### 3. `Duration` time-limit helper (#28)
- **Why:** Swift Testing's `TimeLimitTrait` only offers `.minutes`; sub-minute limits are awkward. The
  issue explicitly suggests wrapping the stdlib `Duration` and converting on the fly.
- **API:** `.timeLimit(.seconds(30))` → rounds up to the nearest `.minutes(n)` Swift Testing accepts
  (document the rounding, since Swift Testing's granularity is minutes).
  ```swift
  extension Testing.Trait where Self == TimeLimitTrait {
    public static func timeLimit(_ duration: Duration) -> Self  // seconds → ceil to minutes
  }
  ```
- **Fit:** extension on the existing retro-conformed `TimeLimitTrait` in
  `Traits/AppleSwiftTesting/TimeLimitSnapshotTrait.swift`. No runtime plumbing — it produces a native
  Swift Testing trait. **Effort S. Risk low.** (Caveat: minutes-granularity is Swift Testing's, not
  ours — the helper is ergonomic sugar, not a finer limit.)

### 4. `Strideable` / range `configurationValues` (#45) — good first issue
- **Why:** users want `configurationValues: stride(from: 0, to: 5, by: 1)` and `1...3` without wrapping
  in an array. The parser already accepts any `Collection` (see `SnapshotConfigurationParser`), so
  ranges (`ClosedRange`, `Range`) and `Set` already flow — but `StrideThrough`/`StrideTo` are
  sequences, not collections, and don't.
- **API:** add sequence-accepting overloads:
  ```swift
  extension SnapshotConfigurationParser {
    public static func parse<S: Sequence>(_ arguments: S) -> [SnapshotConfiguration<S.Element>]
      where S.Element: Sendable
    public static func parse<S: Sequence>(_ arguments: () -> S) -> [SnapshotConfiguration<S.Element>]
      where S.Element: Sendable
  }
  ```
  and the matching `configurationValues:` macro overloads. The issue muses "Comparable vs Strideable" —
  the honest answer is **neither**: accept `Sequence` and materialise with `Array(_:)`, exactly as the
  existing `Collection` overload does.
- **Fit:** `SnapshotConfiguration/SnapshotConfigurationParser.swift` (overloads) + the
  `configurationValues:` macro signatures. **Effort S. Risk low** (watch overload-resolution ambiguity
  vs the existing `[T]` and `Collection` overloads — array args must keep resolving to `[T]`; tests
  must cover `stride`, `Range`, `Set`, `Array` side by side).

### 5. `UITableViewCell` / `.contentView` ergonomics (#64) — investigate first
- **Why:** users must pass `cell.contentView` instead of the cell, or the snapshot is wrong. Unclear
  whether that's a library hosting/layout bug or client-side (the maintainer says "could be client
  code"). This is a *diagnosis before design* item.
- **Plan:** reproduce with a `UITableViewCell` fixture through the `SnapshotViewController` path
  (`SnapshotViewGenerator+UIView.swift`). If the cell's own view hierarchy isn't laid out (cells expect
  a table to size them), either (a) document the `.contentView` requirement loudly, or (b) add a
  cell-aware convenience that wraps the cell in a sized container and forces a layout pass before
  snapshotting.
- **Fit:** `SnapshotViewGenerator+UIView.swift` / `AppKitImageRenderer`-equivalent UIKit render path.
  **Effort M** (mostly investigation). **Risk medium** — don't ship a convenience until the root cause
  is known, or it papers over a real layout bug.

### 6. Config combinators (#2) & builder (#1)
- **Why:** `#2` wants `product`/`zip` over `configurationValues` (Cartesian and pairwise), and `#1`
  wants a result-builder to assemble `configurations`. Both are about expressing large matrices
  readably. The issue itself flags the danger: naïve `product` explodes combinatorially (Swift
  Testing's own docs warn about this).
- **API:**
  ```swift
  // Combinators (#2)
  extension SnapshotConfiguration {
    static func product<A, B>(_ a: [SnapshotConfiguration<A>], _ b: [SnapshotConfiguration<B>])
      -> [SnapshotConfiguration<(A, B)>]           // guarded: precondition/diagnostic on huge N×M
    static func zip<A, B>(_ a: [SnapshotConfiguration<A>], _ b: [SnapshotConfiguration<B>])
      -> [SnapshotConfiguration<(A, B)>]
  }
  // Builder (#1)
  @resultBuilder struct SnapshotConfigurationBuilder { /* buildBlock, buildArray, buildOptional */ }
  ```
  Names of products join with `-` (reuse the tuple naming already in `SnapshotConfiguration`'s doc).
- **Fit:** new files beside `SnapshotConfiguration.swift`; the tuple-2/tuple-3 `#expectSnapshot`
  overloads already consume `SnapshotConfiguration<(A, B)>`/`<(A, B, C)>`, so `product`/`zip` output
  plugs straight in. **Effort M each. Risk medium** — the explosion guard is the whole design; ship it
  with a loud diagnostic (or a required `.explode`-style opt-in) rather than silently generating
  hundreds of references.

### 7. Split `.minimum` sizing (the `Length` `#warning`)
- **Why:** `SizesSnapshotTrait+Length.swift:10` carries a standing `#warning` — `.minimum` conflates
  intrinsic-content-size and preferred-content-size, so VCs can't choose. Auto-layout-driven vs
  `preferredContentSize`-driven controllers snapshot at the wrong size.
- **API:** `.minimum(.intrinsicContentSize)` / `.minimum(.preferredContentSize)`; bare `.minimum` stays
  and maps to `.intrinsicContentSize`.
- **Fit:** extend the `Length` enum + the sizing resolution that feeds `makeSnapshotHostingController`'s
  `sizingOptions`. **Effort M. Risk low** (additive; existing references built from `.minimum` are
  unchanged so long as the default maps to today's behaviour — verify against the current baseline).

---

## Delighters (net-new)

### A. #Preview ↔ snapshot-suite bridge (#17) — the loveable bet
- **Why:** the dream workflow — write the view once, get *both* an Xcode canvas preview and a snapshot
  test, never drifting apart. Today they're separate hand-maintained artifacts. The issue's own
  preferred direction is **suite → preview** ("make our preview from the snapshot suite instead of
  making the tests from the preview code"), because `#Preview` is locked down and can't be made to emit
  tests, but a suite *can* emit previews.
- **Hard constraint:** the code that enumerates view-returning functions belongs to deprecated
  `@SnapshotSuite`; native `@Suite` tests return `Void` and contain arbitrary `#expectSnapshot`
  expressions. Adding a flagship feature only to the deprecated macro would pull the product in the
  wrong direction, and a member macro cannot safely recover reusable views from arbitrary test bodies.
- **Design (serious):** spike a new native companion surface that marks a reusable view factory, then
  lets both the test and preview call the same declaration:
  ```swift
  @Suite
  @SnapshotCatalog
  struct MySnapshots {
    @SnapshotScenario(.theme(.all), .sizes(.minimum))
    static func hero() -> some View { HeroView() }
  }

  #Preview { MySnapshots.previews }
  ```
  Tier 1 emits a `previews` accessor from explicitly-marked factories; tier 2 offers one scenario;
  tier 3 applies the same theme/size/padding/background decorators so canvas and snapshot share the
  configuration model. Generated tests are optional: the safest first slice keeps an explicit
  native `@Test { #expectSnapshot(MySnapshots.hero()) }` so adoption does not revive hidden inference.
- **Fit:** a new attached member/peer macro beside the existing macro definitions, plus a shared
  scenario descriptor that reuses the decorator/runtime configuration. Do **not** extend deprecated
  `@SnapshotSuite` as the production design. **Effort L, exploratory. Risk medium-high** (macro-role
  composition, heterogeneous `some View`, and trait-to-preview fidelity). Prototype tier 1 behind a
  throwaway spike before committing.

### B. Attach failed snapshots to the Swift Testing report (`Attachment`)
- **Why:** on failure today the diff lives on disk and the message carries a path; the user hunts for
  files. Swift Testing has `Attachment` — attaching the reference, the freshly-rendered image, and the
  diff *inline* makes failures readable directly in Xcode's test report and CI report UIs. This is the
  single biggest everyday-QoL uplift after precision.
- **Sketch:** in the failure path, before/at `SnapshotFailure.record()`, attach the images:
  ```swift
  // in SnapshotFailure.record() (Testing branch), when image data is available
  Attachment.record(referenceImageData, named: "\(name).reference.png")
  Attachment.record(failureImageData,   named: "\(name).failure.png")
  Attachment.record(diffImageData,      named: "\(name).diff.png")   // if produced
  ```
- **Fit:** `Assertion/SnapshotFailure.swift` (the `record()` Testing branch) — but the failure value
  must *carry* the image data. Today `SnapshotFailure` only holds a message/error; pointfree's
  `verifySnapshot` returns a `String?` message, not images. So this needs the asserter to capture the
  reference + attempt bytes (they exist on disk at known paths, or via a custom `Diffing` that surfaces
  attachments). **Effort M. Risk low** once the bytes are threaded onto `SnapshotFailure`. Guard for the
  XCTest branch (use `XCTAttachment`). Big loveability, low blast radius.

### C. Safe stale-reference pruning (#16)
- **Why:** after a rename, orphaned reference files linger forever — this repo lived that pain during
  its own rebaseline. There is no supported prune; pointfree has no delete option, so this is net-new.
- **Reject the tempting trait design:** deleting a shared `__Snapshots__` directory from a per-test
  `.record(...deletingStaleReferences: true)` scope can race parallel tests and erase references
  another case just recorded. A plain trait also cannot provide a reliable compile-time warning.
- **API:** make pruning a two-phase tool operation: a performed test run writes the set of requested
  reference paths, then `snapshot-migration snapshots prune --manifest <path>` reports orphans by
  default and requires `--apply` to delete. The report must name every file before mutation.
- **Fit:** assertion requests emit a run manifest; `SnapshotMigrationSupport` reuses its dry-run,
  JSON reporting, apply lock, staging, and atomic safety model. **Effort M/L. Risk medium (data loss)**
  — dry-run default, explicit apply, and the existing `flock` are mandatory. Pairs with delighter D.

### D. Stale-reference detection & report (pairs with C)
- **Why:** even without deleting, telling the user "these N reference files match no current test"
  turns silent rot into an actionable list — safer than C and useful on its own. The migration CLI
  already has the scanner/reporter machinery to model this.
- **Sketch:** a `--report-orphans` mode on the CLI (`SnapshotMigrationSupport/Scanning/ProjectScanner`
  + `Reporting/`), or a test-run summary that walks `__Snapshots__` and lists files no assertion
  produced this run. Reuse `MigrationReport`/`JSONReporter` shapes for output.
- **Fit:** `SnapshotMigrationSupport` (CLI mode) and/or a run-level summary hook. **Effort M. Risk low.**

### E. Vanilla SwiftUI without a UIKit/AppKit host (#26)
- **Why:** the library converts SwiftUI to UI/NSViews immediately (`makeSnapshotHostingController`), so
  a pure-SwiftUI path (no hosting controller) is impossible — closing off host-less contexts.
- **Sketch:** a net-new strategy backed by SwiftUI's own `ImageRenderer` (iOS 16 / macOS 13+), which
  rasterises a `View` with no `UIHostingController`. Add `StrategySnapshotTrait.Strategy.swiftUIImage`
  (or `.image(host: .imageRenderer)`) and a render branch that calls `ImageRenderer(content:).uiImage`
  / `.nsImage` and diffs via pointfree's `Diffing.image(precision:perceptualPrecision:)`.
  ```swift
  enum Strategy { case image, recursiveDescription, swiftUIImage }  // additive
  ```
- **Fit:** `StrategySnapshotTrait` (new case) + a new branch in `StrategyAssertionRequestGenerator`.
  **Effort L. Risk medium** — `ImageRenderer` fidelity differs from the host path (no key-window
  materials, different AA); keep both and document the trade-off. This is the *right* net-new strategy,
  not a pointfree passthrough. Composes with precision (delighter shares the tolerance knob).

### F. Auto-record-once ergonomics
- **Why:** first run always fails-then-records; newcomers read the first red run as breakage. A clearer
  "recorded N new references, re-run to verify" run summary (on top of the existing `.missing`
  behaviour) smooths onboarding without changing semantics.
- **Sketch:** detect the "recorded because missing" outcome and emit a single friendly summary comment
  rather than N terse per-assertion messages. Optionally a `.record(.missing)` convenience alias like
  `.bootstrap`.
- **Fit:** messaging on top of the `.missing` path in the asserter / `SnapshotFailure`. **Effort S.
  Risk low.**

### G. Richer naming controls
- **Why:** derived names are lossy (collisions are *detected* and skipped, per
  `SnapshotConfigurationNameCollisions`, but the user then has to hand-name). A small set of naming
  knobs would cut friction: a per-suite name prefix/namespace, a custom name transform, and an explicit
  opt-in to the slash-as-subfolder convention that `AssertionRequestGenerator` already honours.
- **Sketch:** `.snapshotName { config in … }` transform trait, and/or `.snapshotNamespace("Onboarding")`
  to group references under a subfolder without renaming each test.
- **Fit:** `SnapshotNameNormalizer` + the folder logic in `AssertionRequestGenerator`. **Effort S/M.
  Risk low.**

### H. Expose text/data strategies (`.dump` / `.json` / `.lines`)
- **Why:** pointfree ships `Encodable`/`String`/`Any`/`Data`/`URLRequest` diffing strategies. For teams
  whose "snapshot" is a view-model or a JSON payload (not a pixel image), a `.strategy(.json)` /
  `.dump` path turns this into a general Swift Testing snapshot library, not only a UI one.
- **Sketch:** extend `StrategySnapshotTrait.Strategy` and add non-view `#expectSnapshot` overloads that
  accept `Encodable`/`String` values. Larger surface change (the pipeline assumes a
  `SnapshotViewController`), so scope carefully.
- **Fit:** `StrategySnapshotTrait` + a parallel non-view request path. **Effort L. Risk medium**
  (touches the view-centric core assumption). Lower priority — a strategic expansion, not a polish.

---

## Prioritized roadmap

| # | Item | Value | Effort | Risk | Rationale |
| --- | --- | --- | --- | --- | --- |
| 1 | Precision / perceptualPrecision (§1) | High | S | Low | Directly fixes the cross-machine flakiness class this repo lived. Best value-per-line. |
| 2 | Customizable timeout (§2) | Med-High | S/M | Low | Removes a hardcode + standing `#warning`; unblocks slow-CI/async users. |
| 3 | Failed-snapshot `Attachment`s (§B) | High | M | Low | Biggest everyday-QoL uplift; failures become readable in Xcode/CI. |
| 4 | #28 timeLimit + #45 Strideable (§3, §4) | Med | S each | Low | Two cheap, well-scoped issue wins; #45 is a good-first-issue. |
| 5 | #16 delete-stale + orphan report (§C, §D) | High | M | Med (loss) | High value; ship the report (D, safe) before/with the delete (C, guarded). |
| 6 | #Preview bridge (§A) | Very High ceiling | L | Med | The adoption bet. Spike tier 1 first; highest loveability. |
| 7 | Split `.minimum` sizing (§7), #64 cell ergonomics (§5) | Med | M each | Low/Med | Clears a `#warning`; #64 needs diagnosis before design. |
| 8 | Vanilla SwiftUI / ImageRenderer (§E), config builder/combinators (§1/#2 §6) | Med | L / M | Med | Unlocks host-less platforms; combinators need the explosion guard front-and-centre. |
| 9 | Naming controls (§G), auto-record-once (§F) | Med | S/M | Low | Friction-reducers; schedule alongside the above. |
| 10 | Text/data strategies (§H) | Strategic | L | Med | Turns this into a general snapshot library; deliberate scope decision, not polish. |

**First slice (highest value / lowest cost):** precision + perceptualPrecision, the customizable
timeout, and failed-snapshot attachments — all low-risk, all riding the trait recipe or the failure
path, and together they retire the timeout `#warning` and reduce the flakiness class in one release.
