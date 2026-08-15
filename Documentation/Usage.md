# Usage

The preferred API is native Swift Testing plus `#expectSnapshot(...)`.

## Preferred shape

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

@MainActor
@Suite(.theme(.all), .sizes(.minimum))
struct MySnapshots {
  @Test
  func myView() {
    #expectSnapshot(Text("Some text"))
  }
}
```

Mark the suite `@MainActor`. Snapshot values and builders are main-actor isolated for every
family — SwiftUI as much as UIKit and AppKit — so a `@MainActor` suite can build its view
straight from main-actor state, in all four effect flavours. A nonisolated suite works
identically: the isolation lives on the builder, not on the call site, so
`#expectSnapshot { MyView(model: mainActorModel) }` compiles from either.

### Direct values carry effects

A direct value is spliced into the assertion's builder closure, so it may carry any effect the
enclosing test can. All four flavours compose, for SwiftUI and platform values alike:

```swift
#expectSnapshot(Text("Sync"))
try #expectSnapshot(try makeView())
await #expectSnapshot(await makeView())
try await #expectSnapshot(try await makeView())
```

The effect is read from the expression, not from where the keyword sits, so a `try` nested
inside a larger expression works the same way:

```swift
try #expectSnapshot(ProfileCard(header: try makeHeader()))
```

`try?` and `try!` handle the error inside the expression, so those assertions stay
non-throwing and need no `try` at the call site.

Like every builder, the value is produced inside the main-actor hop rather than at the call
site — so a `@MainActor` factory can be called from a nonisolated suite, and an expression with
side effects is evaluated once per size/theme request rather than once per assertion. Hoist
anything that must happen exactly once into a `let` before the assertion.

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

Without any snapshot trait, each unnamed assertion uses the function's base name. Unnamed
assertions therefore refer to the same snapshot; use distinct `named:` values when a test needs
separate references. A loop that executes one call site for several values still needs an explicit
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

The closure is a `@ViewBuilder`, so a snapshot body reads like any other SwiftUI body — sibling
views, `if` / `else`, a bare `if`, `switch` and `ForEach` all work, in every effect flavour and
in the `argument:`, `SnapshotConfiguration` and tuple forms:

```swift
#expectSnapshot(named: "builder-body") {
  Text("Header")

  if isCompact {
    CompactRow()
  }
  else {
    ExpandedRow()
  }

  ForEach(items, id: \.id) { item in
    Row(item: item)
  }
}
```

An explicit `return` opts a closure out of the builder, exactly as it does elsewhere in Swift.
That is what lets an async body do its work first and hand back a single view:

```swift
await #expectSnapshot(named: "async-closure") {
  await viewModel.load()

  return ProfileCard(viewModel: viewModel)
}
```

Without the `return`, every statement in the body has to be a view — `await viewModel.load()`
produces `Void`, which no builder accepts. Either add the `return`, or fold the work into the
view expression itself (`ProfileCard(state: await loadState())`).

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

Your builder is resolved inside that main-actor hop, not on the calling thread, which is why a
nonisolated suite can still read main-actor state from inside `#expectSnapshot`.

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

UIKit and AppKit support the same direct, closure, `SnapshotConfiguration`, and `argument:` forms as
SwiftUI, and their builders are main-actor isolated in the same way (they are not `@ViewBuilder` —
there is no result builder for `UIView` or `NSView`):

```swift
@Test(arguments: ["guest", "member"])
func profile(state: String) {
  #expectSnapshot(argument: state) { state in
    makeProfileView(for: state)
  }
}

@Test
func throwingProfile() throws {
  try #expectSnapshot(named: "throwing-profile") {
    try makeProfileView()
  }
}

@Test
func throwingDirectProfile() throws {
  try #expectSnapshot(try makeProfileView())
}

@Test
func asyncThrowingDirectProfile() async throws {
  try await #expectSnapshot(try await loadProfileView())
}
```

Use `await` for async builders and `try await` for async-throwing builders. Throwing forms rethrow
factory errors and snapshot-pipeline errors; non-throwing forms record those errors as test issues.
`named:` labels the assertion, while `argument:` and `SnapshotConfiguration` provide parameterised
case identity.

### macOS rendering semantics

On macOS, image snapshots are rendered by re-hosting the view in an offscreen window at each
request's size, applying the theme's `NSAppearance` and any `.backgroundColor(...)` decoration,
and running a full Auto Layout pass before drawing — mirroring how the UIKit path re-hosts per
request. The bitmap is drawn in the sRGB color space at the request's scale:

- `.sizes(..., scale:)` and device scales are honoured exactly (`scale: 2.0` produces @2x pixels).
- An unspecified scale renders at two pixels per point. Unlike iOS, macOS has no deterministic
  device scale to inherit — following the screen's backing scale would make committed references
  differ between Retina and non-Retina machines — so the scale is fixed rather than inherited.
  It is fixed at `2` because every shipping Mac is Retina: rendering at `1` would test a density
  no user sees, and would make hairlines, single-pixel borders and text antialiasing
  unrepresentable. Pass `scale:` explicitly for any other density.
- `WKWebView`-specific capture (pointfree's `takeSnapshot` special case) does not apply to the
  macOS image strategy; web views render like any other view via `cacheDisplay`.

## Legacy macros

`@SnapshotSuite` and `@SnapshotTest` are deprecated. [MIGRATION.md](../MIGRATION.md) summarises the mapping; the before-and-after examples and the full guide live in the [migrator repository](https://github.com/adammcarter/swift-snapshot-testing-macros-migrator/blob/main/MIGRATION.md), along with the tool that performs the migration.
