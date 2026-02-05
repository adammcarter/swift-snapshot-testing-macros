[![Snapshot Tests](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml/badge.svg)](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml)

# Overview

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

---
---

# Customisation

---

# Sensible defaults

Here, the macro uses sensible defaults to generate snapshot tests for the `myView()` function.

These sensible defaults include sizing the snapshots to its minimum size and even rendering them in both light and dark mode variants.

The above code example produces these images when run:

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/ae13d955-a284-42b9-8977-bd57ba625d2d) | ![](https://github.com/user-attachments/assets/fa4cca2e-8391-485a-b959-0989d1dc1eea) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

These defaults can be overriden using traits, similar to Swift Testing, to change how the snapshots are rendered as well as other settings like forcing them to record.

_Note the filenames for the images generated above which concisely describe the configuration of the snapshot._



---


# Explicit names

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


---


# Traits

Both `@SnapshotSuite` and `@SnapshotTest` can take predefined traits to overrride and customise the snapshots as well as the way the snapshots are run.

Many of the Swift Testing traits are available here as well as some new ones bespoke to snapshots such as: custom sizing, add padding, force recording.

For more examples of using traits see the [test fixtures](https://github.com/adammcarter/swift-snapshot-testing-macros/tree/main/Tests/SnapshotsIntegrationTests) for both `SnapshotSuite` and `SnapshotTest`.


## Inheritance

Traits can be added to either the `@SnapshotSuite` to apply the traits to all the tests or to specific `@SnapshotTest`s to override that one specific test.

> ⚠️ When applying a trait to `@SnapshotTest` it will override the `@SnapshotSuite` trait if one exists explicitly or implicitly (eg a default value).

Traits can be used with other traits in the same suite or test declaration.

> ⚠️ Don't use multiple traits of the same kind in the same suite or test as this will not work. You can only override traits - e.g. set a device size for all tests in a suite and overrride the size in a specific test.


## Sizes

### Device(s)

You can set the rendered image's size to a speficic device size by passing one or more device sizes to this trait.

Passing more than one size will generate a bespoke snapshot for each of the devices.

```swift
// 📱 Use explicit device sizes

@Suite
@SnapshotSuite(
  .sizes(devices: .iPhoneX, .iPadPro11) // ⬅️ Set the devices for all the tests in this suite
)
struct MySnapshots {

  @SnapshotTest
  func myView() -> some View {
    Text("Some text")
  }

  @SnapshotTest
  func anotherView() -> some View {
    Text("Some other text")
  }

  @SnapshotTest(
    .sizes(devices: .iPhoneX) // ⬅️ Set this test to be iPhone sized
  )
  func myPhoneView() -> some View {
    Text("I'm the size of a phone")
  }
}
```

<details>
<summary>Sample code renderings</summary>

Here you can see the files that have been rendered:

<img width="316" alt="Screenshot of the explicit device sizes snapshots output" src="https://github.com/user-attachments/assets/3f9947fa-1cad-498f-87b8-caeb3af65320">

_Note how `myPhoneView()` only has images for the iPhoneX size._

</details>

In this mode the device size is also included in the name of the snapshot test for ease of understanding.

#### `fitting`

Optionally, you can set the `fitting` parameter to specify which dimensions you want to use of the device,

- `widthAndHeight` - use both width and height of the device
- `widthButMinimumHeight` - use the width of the device with the minimum height of the view
- `heightButMinimumWidth` - use the height of the device with the minimum width of the view

These options might be useful for example if rendering a row of a  list or a table view cell, where you might use `widthButMinimumHeight` so the view expands the width of the device while using the minimum possible height of the view.

```swift
// 📱 Set a fitting size

@Suite
@MainActor
@SnapshotSuite(
  .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight) // ⬅️ Use device width with minimum height
)
struct MySnapshots {

  @SnapshotTest
  func myListRow() -> some View {
    HStack {
      Image(systemName: "person.fill")

      Text("My account")

      Spacer()
    }
    .padding()
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/6898f7fa-14de-4b6e-add8-043fc34db21b) | ![](https://github.com/user-attachments/assets/1f09cd43-a13d-44b8-b5c1-e1b2a3f9375f) |
| Filename | `myListRow_iPhoneX-min-height_light.1.png` | `myListRow_iPhoneX-min-height_dark.1.png` |

</details>

---

### Custom wdth(s) and height(s)

Another version of the sizes trait allows for explicit sizes to be set.

These sizes can be an explicit size in points or a predefined size `.minimum`

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(.sizes(width: 320, height: 480))
  func size320x480() -> some View {
    Text("320x480 size")
  }

  @SnapshotTest(.sizes(width: 320))
  func width320() -> some View {
    Text("320 width")
  }

  @SnapshotTest(.sizes(.minimum))
  func minimumSize() -> some View {
    Text("Minimum size")
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

<img width="298" alt="Screenshot of the custom width and height sizes output" src="https://github.com/user-attachments/assets/b7b498f3-fff5-4b94-be9e-058ea4f81e87">

</details>

We can also speicify multiple sizes:

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(
    .sizes(
      SizesSnapshotTrait.Size(width: 320, height: 480),
      SizesSnapshotTrait.Size(width: 600, height: 200)
    )
  )
  func testMultipleSizes() -> some View {
    Text("Will render in different sizes")
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

<img width="319" alt="Screenshot of the multiple sizes output" src="https://github.com/user-attachments/assets/6265dbea-d9f2-4167-bcc4-bb923325192a">

</details>

---

## Padding

Sometimes when rendering snapshots we might need to add padding around the image for readability.

You can use the padding trait to add a set amount of padding around the view before its snapshot is rendered.

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(.padding)
  func paddingDefault() -> some View {
    Text("Add system default padding to all sides")
  }

  @SnapshotTest(.padding(20))
  func padding20() -> some View {
    Text("Add 20 padding to all sides")
  }

  @SnapshotTest(.padding(.horizontal, 15))
  func paddingSpecificSides() -> some View {
    Text("Add 15 padding to horizontal sides")
  }

  @SnapshotTest(
    .padding(
      EdgeInsets(
        top: 20,
        leading: 30,
        bottom: 10,
        trailing: 40
      )
    )
  )
  func paddingEdgeInsets() -> some View {
    Text("Add specific edge inset padding")
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/d967bb14-4bac-4776-b03a-d8b8c3b67395) | ![](https://github.com/user-attachments/assets/1b519c47-70ee-4374-bf69-d0817f66b598) |
| Filename | `padding20_min-size_light.1.png` | `padding20_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/21bb9d0e-46a4-4eb9-a589-ba6673a9f1a1) | ![](https://github.com/user-attachments/assets/1d5f1232-7b6a-465c-b51b-7b5912c17ea1) |
| Filename | `paddingDefault_min-size_light.1.png` | `paddingDefault_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/9551beb9-7423-4ae8-bbca-e738a10cc4cf) | ![](https://github.com/user-attachments/assets/d6f64c7e-6a52-417c-b0e6-3207130a3241) |
| Filename | `paddingEdgeInsets_min-size_light.1.png` | `paddingEdgeInsets_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/18592765-5a57-48aa-8c86-ac4526ca2300) | ![](https://github.com/user-attachments/assets/26e164ca-a27b-4533-b998-53a04007c05a) |
| Filename | `paddingSpecificSides_min-size_light.1.png` | `paddingSpecificSides_min-size_dark.1.png` |

</details>

---

## Background color

Sometimes when rendering snapshots we might need to add a specific background colour.

While you can bake this in to the view that gets returned this can add some unnecessary ceremony, especially when using UIKit views where you might need to assign the value just to set the background colour.

By default, the snapshots will render using the [`UIColor.systemBackground`](https://developer.apple.com/documentation/uikit/uicolor/systembackground) color.

You can use the `.backgroundColor` trait to specify the background of a test or all tests inside of a suite.

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(
    .backgroundColor(.red)
  )
  func red() -> some View {
    Text("Red")
  }

  @SnapshotTest(
    .backgroundColor(.blue)
  )
  func blue() -> some View {
    Text("Blue")
  }

  @SnapshotTest(
    .backgroundColor(.green)
  )
  func green() -> some View {
    Text("Green")
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/7ba29ef4-222e-4f39-977a-0f53ac4445ef) | ![](https://github.com/user-attachments/assets/da27c16d-5844-4f01-8e9a-14c289468df1) |
| Filename | `red_min-size_light.1.png` | `red_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/bdbc53eb-ed80-4fae-87c7-67c52226204b) | ![](https://github.com/user-attachments/assets/f5d6df25-584f-467d-a207-8826b2f59abf) |
| Filename | `blue_min-size_light.1.png` | `blue_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/9f9adbc3-1eaa-42d2-9f61-c5f205a2acbf) | ![](https://github.com/user-attachments/assets/333e8b84-773e-4fed-a374-f9f07e235a9e) |
| Filename | `green_min-size_light.1.png` | `green_min-size_dark.1.png` |

</details>

---

## Theme(s)

Use this trait to specify a specific theme (light _or_ dark) or to set all themes (light and dark).

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(.theme(.light))
  func light() -> some View {
    Text("Light theme")
  }

  @SnapshotTest(.theme(.dark))
  func dark() -> some View {
    Text("Dark theme")
  }

  @SnapshotTest(.theme(.all))
  func all() -> some View {
    Text("Both light and dark")
  }
}
```

<details>
<summary>Sample code renderings</summary>

The above code renders these images:

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/3ac09f9a-b6d3-4905-aaf2-fe99537cc90b) | n/a |
| Filename | `light_min-size_light.1.png` | n/a |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | n/a | ![](https://github.com/user-attachments/assets/70648352-100f-4130-a554-e5e1baa28f78) |
| Filename | n/a | `dark_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/84f74130-92f7-408f-ad5e-9f731b375b5e) | ![](https://github.com/user-attachments/assets/78dcd70f-820e-411f-8202-76777731915a) |
| Filename | `all_min-size_light.1.png` | `all_min-size_dark.1.png` |

</details>

---

## Record

Use this trait to force a test or entire suite to re-render their images

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(.record(true)) // ⬅️ Force snapshots in to record mode
  func recordTrue() -> some View {
    Text("Force record (explicit)")
  }

  @SnapshotTest(.record) // ⬅️ Shorthand version of '.record(true)'
  func record() -> some View {
    Text("Force record")
  }

  @SnapshotTest(.record(false)) // ⬅️ Default value so not needed
  func recordFalse() -> some View {
    Text("Doesn't re-record")
  }
}
```

---

## Strategy

Use this trait to change the snapshot strategy and the snapshot's output.

Supported strategies:
- `image` (default): A snapshot strategy for comparing views based on pixel equality.
- `recursiveDescription`: A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.

```swift
@Suite
@SnapshotSuite
struct StrategySnapshots {

  @SnapshotTest(
    .strategy(.image)
  )
  func image() -> some View {
    Text("generates an image file")
  }

  @SnapshotTest(
    .strategy(.recursiveDescription)
  )
  func recursiveDescription() -> some View {
    Text("generates a recursive description text file")
  }
}
```

---

## Swift Testing traits

Snapshot testing supports most of the SwiftTesting traits too so they can also be passed along:

- [Bug](https://developer.apple.com/documentation/testing/associatingbugs)
- [Condition](https://developer.apple.com/documentation/testing/conditiontrait)
- [Tag](https://developer.apple.com/documentation/testing/addingtags)
- [TimeLimit](https://developer.apple.com/documentation/testing/timelimittrait)

These use the same format and callsites as the Swift Testing equivalent for ease of use - you can see the docs in Swift Testing for more info.

---
---

# Parameterised tests

Just as in Swift Testing you can pass [arguments](https://developer.apple.com/documentation/testing/parameterizedtesting), SnapshotTestingMacros uses configurations.

These configurations take a name and a value so the snapshots can be grouped on their configuration and create a cleaner, easier to navigate library of reference snapshot on disk.

## Configurations

You can pass configurations, creating instances of `SnapshotConfiguration` to define the name and the value you want to pass.

This will run the function once for every configuration passing in the value.

For example, the below code calls `myView(value:)` twice; the first time with `value: 1` and the second time with `value: 2`.

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(
    configurations: [
      SnapshotConfiguration(name: "Name 1", value: 1),
      SnapshotConfiguration(name: "Name 2", value: 2),
    ]
  )
  func myView(value: Int) -> some View {
    Text("value: \(value)")
  }
}
```

On disk a folder is created for each configuration, with each folder containing the snapshots for that configuration.

> 💡
> This is especially useful if you set traits with multiple variants, e.g. multiple sizes and themes where the number of snapshots can quickly grow.

<img width="516" alt="Screenshot of folder hierarchy for the configuration snapshots" src="https://github.com/user-attachments/assets/ea66538d-231e-49d4-b578-a75ed7f48975">

<details>
<summary>'Name 1' folder snapshots</summary>

The above code renders these images:

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/eee2ce95-d888-44f9-b452-fb71137d6890) | ![](https://github.com/user-attachments/assets/e11772fc-e50f-4f04-8a98-a74d069760a6) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

</details>

<details>
<summary>'Name 2' folder snapshots</summary>

The above code renders these images:

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/13bc6dfd-840f-4af9-a642-b20bf6878211) | ![](https://github.com/user-attachments/assets/e932c6f9-4171-4380-ac12-9eade0866305) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

</details>

### Value

`value:` can be anything you'd like, from primitive types to your own struct, class or tuples.

When using tuples as the value, the macro library will unpack the values and pass them along to your function for ease of use.

For example, below, the tuple value `(Int, String)` is unpacked and passed along to `myView(int: Int, string: String)`'s parameters.

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(
    configurations: [
      SnapshotConfiguration(name: "Name 1", value: (1, "one")),
      SnapshotConfiguration(name: "Name 2", value: (2, "two")),
    ]
  )
  func myView(int: Int, string: String) -> some View { // ⬅️ Note how the tuple values from 'value:' are unpacked in this function's parameters
    Text("value: \(int) is typed as: \(string)")
  }
}
```

<details>
<summary>Rendered snapshots</summary>

The above code renders these images:

'Name 1' folder snapshots

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/d5742413-e01f-4807-9169-6038278007c6) | ![](https://github.com/user-attachments/assets/17fa3a7a-eb4b-46b2-86be-a38a12ec2297) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

'Name 2' folder snapshots

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.com/user-attachments/assets/b5bd187b-8c3b-466c-933a-c9e1f21a2719) | ![](https://github.com/user-attachments/assets/75960e42-be98-46ba-b63a-6c27ac13e616) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

</details>


### Closures and functions

`configurations` can also accept a function or closure.

This allows us to define complex configurations in a helper function and pass this along for a cleaner callsite or more complex setups.

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(configurations: configurations) // ⬅️ Pass in the configurations() function to make our configurations
  func myView(int: Int, string: String) -> some View {
    Text("value: \(int) is typed as: \(string)")
  }
}

private func configurations() -> [SnapshotConfiguration<(Int, String)>] {
  [
    SnapshotConfiguration(name: "Name 1", value: (1, "one")),
    SnapshotConfiguration(name: "Name 2", value: (2, "two")),
  ]
}
```

Or using a more complex setup:

```swift
@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(configurations: MyConfigurationGenerator.generateConfigurations)
  func myView(int: Int) -> some View {
    Text("value: \(int)")
  }
}

private struct MyConfigurationGenerator {
  static func generateConfigurations() -> [SnapshotConfiguration<Int>] {
    // Some really complex logic ...

    return []
  }
}
```


## Configuration Values

Sometimes the name of a configuration can be inferred from the value.

Using the `configurationValues:` parameter solves this problem for us by avoiding unnecessary duplication of name and value.

### Examples

#### Int

This simple case adds unnecessary ceremony and maintenance by duplicating the name and value:

```swift
// ⚠️ This works but isn't optimal

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(configurations: [
    SnapshotConfiguration(name: "1", value: 1),
    SnapshotConfiguration(name: "2", value: 2)
  ])
  func myView(int: Int) -> some View {
    Text("value: \(int)")
  }
}
```

Where it would be more convenient to have the snapshot generator infer the name from the value:

```
// ✅ This is preferred

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(configurationValues: [1, 2])
  func myView(int: Int) -> some View {
    Text("value: \(int)")
  }
}
```

Both of these output the same configurations and snapshots, but `configurationValues` avoids unnecessary copy/paste. 

<img width="425" alt="Screenshot of folder hierarchy for configuration values" src="https://github.com/user-attachments/assets/f9d6310b-ce88-4bef-a2f3-899bff4c28c9">


#### Enum cases

A more realistic example might be looping over a set of enum cases where me might be tempted to compute the name from the value like so:

```swift
// ⚠️ This works but isn't optimal

enum Compass: CaseIterable {
  case north, east, south, west
}

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(
    configurations: Compass.allCases.map {
      SnapshotConfiguration(name: "\($0)", value: $0) // ⬅️ This might be tempting
    }
  )
  func myView(compass: Compass) -> some View {
    Text("Pointing \(compass)")
  }
}
```

Instead we can use `configurationValues` to infer the name from the enum case's values:

```swift
// ✅ This is preferred

enum Compass: CaseIterable {
  case north, east, south, west
}

@Suite
@SnapshotSuite
struct MySnapshots {

  @SnapshotTest(configurationValues: Compass.allCases) // ⬅️ Use configurationValues when the name can be computed
  func myView(compass: Compass) -> some View {
    Text("Pointing \(compass)")
  }
}
```

> 💡 Just like configurations, configurationValues can also take a function/closure to simplify the callsite or do more complext setup.


# Supported views

TODO: Add more docs about supported views

- SwiftUI views
- UIKit:
  - UIView
  - UIViewController


# Running tests

TODO: Add more docs about running tests

- SnapshotsIntegrationTests runs on iPhone 16 - 18.4
- SnapshotsUnitTests runs on macOS
