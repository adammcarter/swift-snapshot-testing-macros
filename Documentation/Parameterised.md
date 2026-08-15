# Parameterised tests

Use Swift Testing parameterisation with either `SnapshotConfiguration` or ordinary test arguments.

Every case must provide stable snapshot identity. Use `SnapshotConfiguration` or pass the case
through `argument:`. A bare `#expectSnapshot(value)` records an issue and skips rendering even
when it has `named:`: the Apple-shipped Testing module does not expose case argument values
through a supported API, so the runtime cannot prove that assertion labels are distinct without
fragile private-layout reflection.

## `SnapshotConfiguration`

`SnapshotConfiguration` carries both the on-disk configuration name and the value passed into the snapshot builder.

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

enum Layout: Sendable {
  case compact
  case regular
}

enum UserState: Sendable {
  case loggedOut
  case loggedIn
}

@Suite(.theme(.all), .sizes(.minimum))
struct ProfileCardSnapshots {
  @Test(arguments: [
    SnapshotConfiguration(name: "compact-empty", value: (Layout.compact, UserState.loggedOut)),
    SnapshotConfiguration(name: "regular-loaded", value: (Layout.regular, UserState.loggedIn)),
  ])
  func configured(configuration: SnapshotConfiguration<(Layout, UserState)>) {
    #expectSnapshot(configuration) { layout, state in
      ProfileCard(layout: layout, state: state)
    }
  }
}
```

Tuple-2 and tuple-3 configurations unpack into the builder closure parameters.

If you also pass `named:`, the explicit name replaces only the assertion name. The configuration scope on disk still comes from the `SnapshotConfiguration`.

SwiftUI, UIKit, and AppKit parameterised builders support synchronous, throwing, async, and async-throwing
builders. Every builder is `@MainActor` isolated.

## `argument:`

Use `argument:` when the value itself already carries a good name and you do not need a separate `SnapshotConfiguration`.

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

enum CountState: Int, CaseIterable, Sendable {
  case zero
  case one
}

@Suite(.theme(.all), .sizes(.minimum))
struct CounterSnapshots {
  @Test(arguments: CountState.allCases)
  func counter(state: CountState) {
    #expectSnapshot(argument: state) { state in
      Text("state-\(state.rawValue)")
    }
  }
}
```

Just like the configuration form, `named:` changes only the assertion name. The derived argument scope still comes from the argument value.

## Platform scope

UIKit and AppKit support these same `SnapshotConfiguration` and `argument:` forms for both views and
view controllers:

```swift
@Test(arguments: ["guest", "member"])
func configured(state: String) {
  #expectSnapshot(argument: state) { state in
    makeProfileView(for: state)
  }
}
```

Use `try`, `await`, or `try await` at the call site for throwing, async, or async-throwing builders.
Throwing builders rethrow factory and snapshot-pipeline errors. `named:` labels the assertion but
does not replace the case identity supplied by `argument:` or `SnapshotConfiguration`.
