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

In v1, UIKit and AppKit support the direct-value overloads only. Closure forms, `SnapshotConfiguration`, and `argument:` helpers remain SwiftUI-only.

## Legacy macros

`@SnapshotSuite` and `@SnapshotTest` are deprecated. See [MIGRATION.md](../MIGRATION.md) for before-and-after examples.
