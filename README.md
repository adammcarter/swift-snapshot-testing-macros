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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/0af01118-1bf7-4b38-96e4-29a28f3ad13b) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/ce5416fa-9746-411d-b781-fcf251ac1655) |
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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/0af01118-1bf7-4b38-96e4-29a28f3ad13b) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/ce5416fa-9746-411d-b781-fcf251ac1655) |
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

<img width="316" alt="Screenshot of the explicit device sizes snapshots output" src="https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/44800863-af50-4b00-bfdf-2f62820f9b35">

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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/012fecfa-2528-413e-b701-f56ae384193c) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/3a2f0e6a-9c94-4532-aa2e-592e68ea5631) |
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

<img width="298" alt="Screenshot of the custom width and height sizes output" src="https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/df80c7c6-b8aa-4167-94c1-38659bc8bd3d">

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

<img width="319" alt="Screenshot of the multiple sizes output" src="https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/929c0130-aac3-4be6-b9be-86ff465a2fdd">

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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/c81643c5-d920-4e63-bed5-300675a8fbf8) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/6ff93683-818f-46d3-a03a-6ff2a7ce7e1b) |
| Filename | `padding20_min-size_light.1.png` | `padding20_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/32b915b5-04a9-45a7-82b1-7ba29fa4c4e8) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/2794a534-6009-4f5b-ac75-c3b189bb4b1f) |
| Filename | `paddingDefault_min-size_light.1.png` | `paddingDefault_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/6c58b150-d094-4365-8e5d-bd0a12347fad) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/3c77004d-6e33-4732-a9b1-e4a616d2aae0) |
| Filename | `paddingEdgeInsets_min-size_light.1.png` | `paddingEdgeInsets_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/d25b4fba-00ef-4112-a479-9d589cb53511) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/b6621325-f3f4-4ced-aada-f502dd5f0e99) |
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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/f50d215e-17fe-40af-8e72-e918560f8411) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/2a4309d4-f424-46cf-aff5-1dec87137467) |
| Filename | `red_min-size_light.1.png` | `red_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/3586c61d-e5eb-43b6-a3f4-7df4855c9afa) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/525ab5ac-a575-42de-9ef4-6309dad88559) |
| Filename | `blue_min-size_light.1.png` | `blue_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/a30cc7d0-6a4f-4835-841f-f9532b35e79b) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/b3740bd4-87a2-489b-aeb1-0dc226b7892b) |
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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/1b2c8758-270e-44ac-bb8c-fde8fa1866a8) | n/a |
| Filename | `light_min-size_light.1.png` | n/a |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | n/a | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/5642e2fa-9d08-4c1e-9049-d017087ed335) |
| Filename | n/a | `dark_min-size_dark.1.png` |

| Theme | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/cdae5640-4981-4c26-b38d-5a8b95984082) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/e7890ab4-808a-45c1-b99e-70f12193bbca) |
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

<img width="516" alt="Screenshot of folder hierarchy for the configuration snapshots" src="https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/7e4922a2-c01d-4338-a811-004d09ad1882">

<details>
<summary>'Name 1' folder snapshots</summary>

The above code renders these images:

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/cabf8b13-3aa6-42b4-a4a0-dc0e8fa93b39) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/1feab1ff-6cda-46eb-9f82-24129b87d335) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

</details>

<details>
<summary>'Name 2' folder snapshots</summary>

The above code renders these images:

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/4859e226-57de-4ab8-87a4-813eda30aa42) | ![]([https://github.com/user-attachments/assets/e932c6f9-4171-4380-ac12-9eade0866305](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/07c9742a-89e5-48ed-8f4e-5b379083ce6b)) |
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
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/cb902300-bef9-4db1-9723-9f2af390c6d3) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/d2414dec-d900-4878-9125-376150a8a567) |
| Filename | `myView_min-size_light.1.png` | `myView_min-size_dark.1.png` |

'Name 2' folder snapshots

| Configuration | Light mode | Dark mode |
|--:|-|-|
| Image | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/9657831b-28e9-4657-aefb-ca2ae9d9b1f9) | ![](https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/02703e03-9290-4b58-8042-7f41db7bd0bc) |
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

<img width="425" alt="Screenshot of folder hierarchy for configuration values" src="https://github.atcloud.io/AutoTrader/swift-snapshot-testing-macros/assets/215/e5ceff92-1724-4569-bcb3-f391a3558dc4">


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
- AppKit:
  - NSView
  - NSViewController


# Running tests

TODO: Add more docs about running tests

- SnapshotsIntegrationTests runs on iPhone 16 - 18.4
- SnapshotsUnitTests runs on macOS
