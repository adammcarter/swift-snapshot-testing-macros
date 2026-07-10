# Usage

The preferred API is native Swift Testing plus `#expectSnapshot(...)`.

## Preferred shape

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite(.theme(.all), .sizes(.minimum))
struct MySnapshots {
  @Test
  func myView() {
    #expectSnapshot(Text("Some text"))
  }
}
```

## Named snapshots

`@Test("...")` changes the test's display name in Swift Testing output. `named:` changes the snapshot artifact name on disk.

```swift
@Suite(.theme(.all), .sizes(.minimum))
struct ProfileCardSnapshots {
  @Test("Profile card")
  func compactCard() {
    #expectSnapshot(ProfileCard(), named: "compact")
  }
}
```

### Slash-delimited names create subfolders

A `/` in a snapshot display name means "subfolder": `named: "Menu/Item"` stores the reference
inside a `Menu/` folder under the test file's snapshot folder, with `Item` as the artifact
name. The convention applies identically to parameterized tests —
`#expectSnapshot(configuration, named: "Menu/Item")` nests `Menu/Item/` and names each case's
artifact `<case>_Item_<size>_<theme>` inside it.

### Repeated unnamed assertions

When a test makes several unnamed `#expectSnapshot` calls, all calls within one execution of
the test body share one naming scope as long as at least one snapshot trait (for example
`.theme(...)` or `.sizes(...)`) is applied to the test or its suite: the first assertion uses
the function's base name and later ones append deterministic `-2`, `-3`, … suffixes. This
scope covers helper functions and child tasks spawned by the test body, and it resets for
every new run of the test (including retries and repetitions), so artifact names stay stable
across runs.

The `-2`, `-3`, … mapping follows execution order. Concurrent unnamed assertions have no
deterministic execution order, so give them explicit `named:` values or configuration identity.

The trailing `.N` reference-file identifier (as in `profileCard_min-size_light.1.png`) is
part of the same scope: assertions that resolve the same reference path within one run count
up deterministically in assertion order, and every new run restarts at `.1` — so repeated
in-process test iterations and parallel tests always resolve the same reference files instead
of depending on a process-wide counter.

Without any snapshot trait there is no safe attempt-lifetime owner for an ordered counter.
Each unnamed assertion therefore uses a deterministic source-location suffix, so distinct
call sites cannot silently share one reference and the same call site stays stable across
runs. Moving an assertion changes that suffix; use `named:` when the on-disk name must survive
source movement. A loop that executes one call site for several values still needs an explicit
`named:` value per iteration or a snapshot trait to provide an ordered attempt scope.

### Unnamed snapshots in parameterised tests

Swift Testing publicly exposes whether a case is parameterised, but the Apple-shipped module
does not expose its argument values. A bare unnamed `#expectSnapshot(value)` therefore cannot
derive a supported, collision-free case identity. It records an issue and skips rendering
instead of letting cases share one reference.

Pass the case through `#expectSnapshot(argument:)` or `SnapshotConfiguration`. `named:` may
still label that configured assertion, but cannot establish case identity by itself. See
[Parameterised tests](Parameterised.md).

## SwiftUI closure forms

SwiftUI supports closure-backed snapshot generation when you want the assertion to own the value creation:

```swift
@Suite(.theme(.all), .sizes(.minimum))
struct ClosureSnapshots {
  @Test
  func syncClosure() {
    #expectSnapshot(named: "sync-closure") {
      Text("Sync closure")
    }
  }

  @Test
  func throwingClosure() throws {
    try #expectSnapshot(named: "throwing-closure") {
      Text("Throwing closure")
    }
  }

  @Test
  func asyncClosure() async {
    await #expectSnapshot(named: "async-closure") {
      Text("Async closure")
    }
  }

  @Test
  func asyncThrowingClosure() async throws {
    try await #expectSnapshot(named: "async-throwing-closure") {
      Text("Async throwing closure")
    }
  }
}
```

## Failure reporting and concurrency

`#expectSnapshot` renders and verifies on the main actor, but every failure is recorded on
the test's own task: a mismatch fails the test that made the assertion (never an orphaned
run-level issue), works under parallel execution, and can be matched with `withKnownIssue`:

```swift
@Test(.theme(.light))
func knownMismatch() {
  withKnownIssue {
    #expectSnapshot(ProfileCard())
  }
}
```

The `async` overloads bridge to the main actor structurally (`await`), staying on the test's
task for the render — they do not block the calling thread while the snapshot runs.

## UIKit and AppKit direct values

UIKit and AppKit support the direct-value overloads in the native API:

```swift
import SnapshotTestingMacros
import Testing

@Suite(.theme(.all), .sizes(.minimum))
struct PlatformSnapshots {
  @Test
  func profileController() {
    #expectSnapshot(makeProfileController())
  }
}
```

For these platform views, the recommended pattern is:

1. Keep the test itself as a regular `@Test`.
2. Build the view or controller in a helper expression.
3. Pass that expression directly to `#expectSnapshot(...)`.

That keeps the call site native while still creating the platform view on the main actor inside the snapshot operation.

Under `.sizes(.minimum)`, views that size themselves through Auto Layout (constraints or an
intrinsic content size) are measured by compressing them to their smallest fitting size.
Frame-based views — no constraints and no intrinsic content size, such as a plain view built
with `init(frame:)` or a controller migrated from pointfree's `assertSnapshot(of:as:)` — are
measured at their current frame size instead, so they do not need explicit size constraints to
snapshot. A frame-based view whose frame is zero still fails with a sizing error rather than
recording an empty artifact.

In v1, UIKit and AppKit support the direct-value overloads only. Closure forms, `SnapshotConfiguration`, and `argument:` helpers remain SwiftUI-only.

### macOS rendering semantics

On macOS, image snapshots are rendered by re-hosting the view in an offscreen window at each
request's size, applying the theme's `NSAppearance` and any `.backgroundColor(...)` decoration,
and running a full Auto Layout pass before drawing — mirroring how the UIKit path re-hosts per
request. The bitmap is drawn in the sRGB color space at the request's scale:

- `.sizes(..., scale:)` and device scales are honoured exactly (`scale: 2.0` produces @2x pixels).
- An unspecified scale renders at one pixel per point. Unlike iOS, macOS has no deterministic
  device scale to inherit — following the screen's backing scale would make committed references
  differ between Retina and non-Retina machines.
- `WKWebView`-specific capture (pointfree's `takeSnapshot` special case) does not apply to the
  macOS image strategy; web views render like any other view via `cacheDisplay`.

## Legacy macros

`@SnapshotSuite` and `@SnapshotTest` are deprecated. See [MIGRATION.md](../MIGRATION.md) for before-and-after examples.
