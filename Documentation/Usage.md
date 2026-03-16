# Usage

`SnapshotTestingMacros` is a thin layer over [swift-testing](https://github.com/swiftlang/swift-testing) and [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to allow for macro based snapshots using a syntax similar to Swift Testing.

Just as Swift Testing has `@Suite` and `@Test`, `SnapshotTestingMacros` uses `@SnapshotSuite` and `@SnapshotTest` to mark up code.

This allows for snapshots to quickly be created by simply marking up functions that return views.

## Example code

In the simplest case this is all that's needed for a snapshot test:

```swift
// ✅ Create a simple snapshot test for some SwiftUI text.

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest
  func myView() -> some View {
    Text("Some text")
  }
}
```

> Note that while `@Suite` isn't explicitly needed to run the snapshots, it's currently recommneded so Xcode can pickup the generated Suite inside the macro. Due to macro limitations it seems that Xcode cannot see Suites when they're embedded inside macro expansion code.

## Async and Throws support

Snapshot tests can also be `async` and/or `throws`, allowing you to perform asynchronous work or throw errors within your snapshot generation logic.

```swift
@Suite
@SnapshotSuite
struct AsyncSnapshots {

  @SnapshotTest
  func asyncView() async throws -> some View {
    let data = try await fetchData()
    return MyView(data: data)
  }
}
```

## Explicit names

By default, snapshots have a display name based on the name of the function that makes the view, but this can be overriden for more user friendly names.

Just like Swift Testing the `@SnapshotTest` macro can take a display name as its first argument:

```swift
// ✅ Use explicit names for test

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest("Sample text") // ⬅️ Added display name
  func myView() -> some View {
    Text("Some text")
  }
}
```

This allows tests to adopt these display names in the generated file name for the snapshot images.

<details>
<summary>Sample code renderings</summary>

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/ae13d955-a284-42b9-8977-bd57ba625d2d) | ![](https://github.com/user-attachments/assets/fa4cca2e-8391-485a-b959-0989d1dc1eea) |
| Filename | `Sample-text_min-size_light.1.png` | `Sample-text_min-size_dark.1.png` |

_Note how the filenames now use the 'Sample-text' display name for their prefix._

</details>

> ⚠️ `@SnapshotSuite` can also have a display name but this is currently unused. There's future plans to use this as potentially the folder name for the snapshots and (if/when Xcode supports it) overloading the display name of the Suites so it can be seen in the Xcode GUI in the Test Navigator.
