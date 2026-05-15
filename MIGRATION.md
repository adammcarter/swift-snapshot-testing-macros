# Migration

The preferred API is now native Swift Testing plus `#expectSnapshot(...)`.

The legacy `@SnapshotSuite` and `@SnapshotTest` macros are still available for migration, but they are deprecated.

## Quick mapping

| Legacy surface | Native replacement |
| --- | --- |
| `@SnapshotSuite` | `@Suite` plus snapshot traits |
| `@SnapshotTest` | `@Test` plus `#expectSnapshot(...)` |
| `@SnapshotTest("Name")` | `@Test("Name")` for test output, plus `named:` for snapshot artifact naming when needed |
| `@SnapshotTest(configurations: ...)` | `@Test(arguments: [SnapshotConfiguration(...)])` plus `#expectSnapshot(configuration) { ... }` |
| `@SnapshotTest(configurationValues: ...)` | `@Test(arguments: values)` plus `#expectSnapshot(argument: value) { ... }` |

## Basic before and after

### Before

```swift
@Suite
@SnapshotSuite
struct ProfileCardSnapshots {
  @SnapshotTest("Default")
  func profileCard() -> some View {
    ProfileCard()
  }
}
```

### After

```swift
@Suite(.theme(.all), .sizes(.minimum))
struct ProfileCardSnapshots {
  @Test("Default")
  func profileCard() {
    #expectSnapshot(ProfileCard(), named: "Default")
  }
}
```

## Parameterised migration

### Before

```swift
@Suite
@SnapshotSuite
struct UserProfileSnapshots {
  @SnapshotTest(configurations: [
    SnapshotConfiguration(name: "logged-out", value: UserState.loggedOut),
    SnapshotConfiguration(name: "logged-in", value: UserState.loggedIn),
  ])
  func userProfile(state: UserState) -> some View {
    UserProfileView(state: state)
  }
}
```

### After

```swift
@Suite(.theme(.all), .sizes(.minimum))
struct UserProfileSnapshots {
  @Test(arguments: [
    SnapshotConfiguration(name: "logged-out", value: UserState.loggedOut),
    SnapshotConfiguration(name: "logged-in", value: UserState.loggedIn),
  ])
  func userProfile(configuration: SnapshotConfiguration<UserState>) {
    #expectSnapshot(configuration) { state in
      UserProfileView(state: state)
    }
  }
}
```

## `configurationValues:` migration

### Before

```swift
@SnapshotTest(configurationValues: makeUserStates())
func userProfile(state: UserState) -> some View {
  UserProfileView(state: state)
}
```

### After

```swift
@Test(arguments: makeUserStates())
func userProfile(state: UserState) {
  #expectSnapshot(argument: state) { state in
    UserProfileView(state: state)
  }
}
```

## UIKit and AppKit

In v1, UIKit and AppKit participate through the direct-value overloads only:

```swift
@Test
func profileController() {
  #expectSnapshot(makeProfileController())
}
```

Use a helper-backed expression for the platform view or controller and keep the test itself as a regular `@Test`. The helper expression is evaluated on the main actor inside the snapshot operation.

SwiftUI keeps the broader convenience surface:

- Direct-value snapshots
- Closure forms
- `SnapshotConfiguration`
- `argument:`

## Next steps

- Update call sites to `@Suite`, `@Test`, and `#expectSnapshot(...)`
- Keep snapshot traits on the suite or test declarations
- See [Documentation/Usage.md](Documentation/Usage.md), [Documentation/Traits.md](Documentation/Traits.md), and [Documentation/Parameterised.md](Documentation/Parameterised.md) for the native forms
