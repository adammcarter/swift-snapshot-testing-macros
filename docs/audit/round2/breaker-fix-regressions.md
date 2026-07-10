# Audit round 2: breaker-fix-regressions

Round-2 breaker pass over fix commits f5d0037..226c017, attacking the fixes themselves for
introduced regressions. Reviewed the source and diffs statically (no build/test run per
constraints). Four issues survived refutation; one brief candidate (NFC/NFD dedup collision) was
refuted — Swift String equality/hashing use Unicode canonical equivalence, so composed/decomposed
forms already hash equal in the `usedNames` Set and get suffixed; only case genuinely disagrees
with the default case-insensitive APFS volume. All four surviving findings have a statically
confirmed code-level evidence chain but need dynamic confirmation (crash mode, filesystem
case-sensitivity, scheduling nondeterminism, hybrid-view collapse).

## MEDIUM

### 1. AppKit renderer fatalErrors on huge-but-finite `.fixed` sizes, crashing the whole test process

- **File**: `Sources/SnapshotTestingMacros/Assertion/RequestGenerator/Generators/AppKitImageRenderer.swift:143`
- **Failure scenario**: A request like `.sizes(width: .fixed(50000), height: .fixed(50000), scale: 2)`
  passes `c43933f`'s size validation (`value > 0 && value.isFinite`, no upper bound), producing a
  ~100000x100000x4-byte (~40 GB) bitmap request. `NSBitmapImageRep(...)` returns `nil`, and
  `drawImage` calls `fatalError("View not renderable ...")` — terminating the entire test process,
  not just failing one test. An even larger finite value (e.g. `.fixed(1e19)`) traps one step
  earlier inside `Int((size.width * displayScale).rounded())` because the product overflows `Int`.
- **Evidence**: `AppKitImageRenderer.swift:122-144`:
  `let pixelsWide = Int((size.width * displayScale).rounded())` ... `guard pixelsWide > 0,
  pixelsHigh > 0, let bitmap = NSBitmapImageRep(...) else { fatalError(...) }`. Reachability:
  `SizeAssertionRequestGenerator` only calls `traitSize.validate()` (positivity/finiteness, no
  max) then passes the absolute `CGSize` unmodified to `StrategyAssertionRequestGenerator
  .makeImageSnapshotting` (lines 119-145), which calls `AppKitImageRenderer.render(...)` with no
  intervening clamp. The UIKit path (lines 36-49) uses pointfree's `.image(size:traits:)`
  strategy instead and is unaffected.
- **Suggested fix**: Throw a recoverable `SnapshotError` (e.g. a new `SizeError.imageTooLarge`)
  when the bitmap can't be allocated or the pixel dimensions are out of a sane range, instead of
  `fatalError`. The render path is already `throws`-capable up to
  `collectSnapshotFailuresSync`, so this requires no new plumbing. Alternatively add an upper
  bound to `Size.validate()`.
- **needs_dynamic_verification**: true

## LOW

### 2. Sanitized dedup key folds punctuation but not case — collides on default case-insensitive APFS

- **File**: `Sources/SnapshotTestingMacros/Assertion/SnapshotExecutionContext.swift:45`
- **Failure scenario**: Two assertions named e.g. "Login Screen" and "login screen" in one attempt
  sanitize to distinct keys `Login-Screen` and `login-screen`; both pass the uniqueness guard with
  no suffix. On the default macOS APFS volume (case-insensitive — the recording environment for
  the AppKit references) pointfree writes `Login-Screen.*.png` and `login-screen.*.png`, which
  resolve to the SAME on-disk file: silent overwrite on record, cross-comparison on verify. This
  reproduces the exact bug class `a297ebe` fixed for punctuation, via case instead.
- **Evidence**: `SnapshotExecutionContext.swift:45-50` `dedupKey` -> `SnapshotNameNormalizer
  .folderComponent` (`SnapshotNameNormalizer.swift:4-8`) only does `\W+`->`-` and trims
  leading/trailing `-`; no lowercasing. `SnapshotExecutionContext.swift:5` `var usedNames =
  Set<String>()` is case-sensitive. `resolvedAssertionName` (lines 20-37) inserts `dedupKey(for:)`
  and only suffixes on collision; the resolved name feeds `NameAssertionRequestGenerator.testName`
  -> reference filename.
- **Suggested fix**: Fold case in the dedup key (accepting benign extra suffixing on
  case-sensitive volumes like Linux CI — correctness on the default macOS FS outweighs a cosmetic
  suffix elsewhere), or document that snapshot names must not differ only by case and emit a
  collision diagnostic for case-only-differing names in one attempt.
- **needs_dynamic_verification**: true

### 3. Attempt-token naming determinism guarantee is false for concurrent child tasks

- **File**: `Sources/SnapshotTestingMacros/Assertion/SnapshotAttemptToken.swift:10`
- **Failure scenario**: `SnapshotAttemptToken`'s doc claims child-task-issued assertions keep
  unnamed suffixes and `.N` reference identifiers "stable and deterministic". That only holds for
  sequential issuance. When the test body issues assertions from concurrent child tasks
  (`withTaskGroup`, two `Task{}`), all children inherit the same token/context, but each
  assertion's name/counter resolves under `nameState.lock` at whatever moment its main-actor hop
  runs — an order fixed by task scheduling, not source order. Two concurrent unnamed assertions
  can have their base-name-vs-"-2" assignment flip between record and verify runs depending on
  scheduling, comparing view A against view B's reference. This is not a data race (the lock plus
  serialized main queue keep each assertion atomic) — it's order nondeterminism, and arguably
  worse than the pre-fix deterministic-collision behavior it replaced (consistently wrong vs.
  flaky).
- **Evidence**: `SnapshotAttemptToken.swift:9-13` (doc claim); `TaskLocalSnapshotExecutionContext
  .resolveContext` (lines 51-57) returns `token.executionContext` when `SnapshotAttemptToken
  .current` is set, and `@TaskLocal` values are inherited by child tasks.
  `SnapshotExecutionContext.resolvedAssertionName` (lines 20-37) mutates `usedNames` under
  `nameState.lock` — atomic but order = lock-acquisition order, which for the sync path is gated
  by `DispatchQueue.main.sync` in `ExpectSnapshotAdapter.runOnMainActor` (lines 1020-1051), i.e.
  scheduling-dependent.
- **Suggested fix**: Either tighten the docs to state the guarantee only holds for sequential
  issuance (requiring explicit `named:` for concurrent child-task assertions), or derive the
  reference identity from a stable source-order key (fileID:line:column) rather than a
  mutation-order counter.
- **needs_dynamic_verification**: true

## IMPROVEMENT

### 4. `preserveFrameBasedSize`'s `constraints.isEmpty` guard misses hybrid frame+internal-constraint containers

- **File**: `Sources/SnapshotTestingMacros/_Convenience/SnapshotView+wrappingInContainerView.swift:58`
- **Failure scenario**: `ec34ac7` added `preserveFrameBasedSize` to pin a frame-based child's size
  before disabling `translatesAutoresizingMaskIntoConstraints`, fixing collapse-to-zero under
  `.minimum` measurement. Its guard `guard childView.constraints.isEmpty else { return }` treats
  ANY non-empty `.constraints` as "already Auto-Layout-sized". But `.constraints` includes
  constraints the view holds for its own subtree, so a custom container that lays out its
  *subviews* via Auto Layout while sizing *itself* purely by frame (no self width/height
  constraint, no intrinsic size override) has a non-empty array and is skipped — the frame pin is
  never applied, `translatesAutoresizingMaskIntoConstraints` is set false anyway, and under the
  default `.minimum x .minimum` measurement the container collapses to zero: the exact failure
  class `ec34ac7` was meant to fix, for this hybrid shape. Pre-existing gap (not a new
  regression), but reachable via the default measurement path for realistic migrated container
  views, and uncovered by `FrameBasedViewSizingTests`.
- **Evidence**: `SnapshotView+wrappingInContainerView.swift:58`
  `guard childView.constraints.isEmpty else { return }`; line 26
  `childController.view.translatesAutoresizingMaskIntoConstraints = false`.
  `SizesSnapshotTrait.swift:22-25` default `current = [.init(width: .minimum, height: .minimum)]`.
  `c43933f`'s `compressedSizeWhenConstrained` passes nil width/height for `.minimum`, so an
  unconstrained-on-self container resolves toward zero.
- **Suggested fix**: Base the "already sized" decision on whether the child has a self-sizing
  constraint or intrinsic size, not on `constraints.isEmpty` — detect a width/height constraint
  whose `firstItem`/`secondItem` resolve to the child itself, or `intrinsicContentSize !=
  noIntrinsicMetric`, and only skip then. Add a `FrameBasedViewSizingTests` case for a frame-sized
  container with internal subview constraints but no self-size constraint.
- **needs_dynamic_verification**: true
