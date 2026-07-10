# Traits

Snapshot traits are regular Swift Testing traits. Apply them to `@Suite` or `@Test`, and every `#expectSnapshot(...)` call in scope uses the resolved trait values.

## Basic example

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite(.theme(.all), .sizes(.minimum))
struct TraitSnapshots {
  @Test(.padding(16), .backgroundColor(.red))
  func paddedCard() {
    #expectSnapshot(Text("Trait-driven snapshot"))
  }
}
```

If the same snapshot trait appears more than once in the same scope chain, the later value wins.

## Common snapshot traits

| Trait | Example | Purpose |
| --- | --- | --- |
| Sizes | `.sizes(.minimum)` | Use intrinsic sizing |
| Sizes | `.sizes(width: 320, height: 480)` | Use fixed dimensions |
| Sizes | `.sizes(devices: .iPhoneX)` | Render at a device size |
| Theme | `.theme(.light)` / `.theme(.dark)` / `.theme(.all)` | Control color-scheme variants |
| Padding | `.padding` / `.padding(16)` / `.padding(.horizontal, 12)` | Add snapshot padding |
| Background color | `.backgroundColor(.red)` | Override the snapshot background |
| Strategy | `.strategy(.image)` / `.strategy(.recursiveDescription)` | Choose image or textual output |
| Record | `.record` / `.record(.all)` / `.record(.missing)` | Control when snapshots are recorded |
| Diff tool | `.diffTool(.default)` | Configure the diff command shown on failure |

When no `.record` or `.diffTool` trait is set, ambient swift-snapshot-testing configuration
applies as usual: your own `withSnapshotTesting(record:diffTool:)`, pointfree's
`.snapshots(record:diffTool:)` trait, and the `SNAPSHOT_TESTING_RECORD` environment variable
(so `SNAPSHOT_TESTING_RECORD=all swift test` re-records as expected). An explicit trait
overrides all of these for its scope.

## Suite-level and test-level traits

Use suite traits for defaults and test traits for local overrides:

```swift
@Suite(.theme(.all), .sizes(devices: .iPhoneX))
struct ProfileCardSnapshots {
  @Test
  func phoneSizedCard() {
    #expectSnapshot(ProfileCard())
  }

  @Test(.sizes(.minimum), .theme(.dark))
  func compactDarkCard() {
    #expectSnapshot(ProfileCard())
  }
}
```

## Swift Testing traits still compose

Snapshot traits compose with standard Swift Testing traits such as `Bug`, `Condition`, `Tag`, and `TimeLimit`.

```swift
@Suite(.theme(.all), .sizes(.minimum))
struct TaggedSnapshots {
  @Test(
    .tags(.init("ui")),
    .timeLimit(.minutes(1))
  )
  func taggedCard() {
    #expectSnapshot(Text("Tagged snapshot"))
  }
}
```

## Platform notes

The same traits apply to SwiftUI, UIKit, and AppKit snapshots. In v1, UIKit and AppKit use the direct-value `#expectSnapshot(...)` overloads, while SwiftUI also supports the closure, `SnapshotConfiguration`, and `argument:` convenience forms.
