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

## Testing Scopes

You can use existing [Swift Testing test scopes](https://developer.apple.com/documentation/testing/testscoping) within your `@SnapshotSuite`s and `@SnapshotTest`s (version 1.1.0 onwards).

You can create your own or use existing scopes by conforming to `SnapshotTest` and/or `SnapshotSuite`.

You can see an example of this in action [here](https://github.com/adammcarter/swift-snapshot-testing-macros/blob/main/Tests/SnapshotsIntegrationTests/Support/MyExampleTrait.swift).

This can be used on a `@SnapshotSuite`, a `@SnapshotTest` or both...

```swift
@Suite
@SnapshotSuite
struct Example {

  @SnapshotTest(
    /// Use an existing `TestScoping` trait with `@SnapshotTest`
    .testScopingTrait(value: "TestScoping")
  )
  func testScoping() -> some View {
    Text(MyExampleTrait.current)
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
