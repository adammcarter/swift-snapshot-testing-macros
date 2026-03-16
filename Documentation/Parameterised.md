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
