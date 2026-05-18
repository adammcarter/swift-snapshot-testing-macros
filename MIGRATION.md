# Migration

The preferred API is now native Swift Testing plus `#expectSnapshot(...)`.

The legacy `@SnapshotSuite` and `@SnapshotTest` macros are still available for migration, but they are deprecated.

## Quick mapping

| Legacy surface | Native replacement |
| --- | --- |
| `@SnapshotSuite` | `@Suite` plus snapshot traits |
| `@SnapshotTest` | `@Test` plus `#expectSnapshot(...)` |
| `@SnapshotTest("Name")` | `@Test("Name")` for test output, plus `named:` for snapshot artifact naming when needed |
| `@SnapshotTest(configurations: ...)` | SwiftUI: `@Test(arguments: [SnapshotConfiguration(...)])` plus `#expectSnapshot(configuration) { ... }`. UIKit/AppKit: keep `@Test(arguments:)`, build the platform value directly, and use `named:` yourself when you need per-argument artifacts. |
| `@SnapshotTest(configurationValues: ...)` | SwiftUI: `@Test(arguments: values)` plus `#expectSnapshot(argument: value) { ... }`. UIKit/AppKit: keep `@Test(arguments:)`, build the platform value directly, and use `named:` yourself when you need per-argument artifacts. |

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

When migrating parameterised UIKit or AppKit snapshots, keep `@Test(arguments:)` on the test, build the platform view or controller from that argument, and pass the direct value to `#expectSnapshot(...)`. If you need separate artifacts per argument, derive a unique `named:` value yourself or split the cases into separate tests. That keeps the cases distinct, but it does not recreate the legacy configuration-scoped folder structure. The `SnapshotConfiguration` and `argument:` convenience builders remain SwiftUI-only in v1.

SwiftUI keeps the broader convenience surface:

- Direct-value snapshots
- Closure forms
- `SnapshotConfiguration`
- `argument:`

## Migration script

Run from a checkout of this repository:

```shell
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo --apply --json-report ./snapshot-migration-report.json
```

The command defaults to dry-run mode. Add `--apply` to write migrated files. Each run also reports total, scan, rewrite/stage, and apply timings in both the console summary and JSON report.

Recommended rollout:

1. Use dry-run first.
2. Resolve skip and failure items from the report output.
3. Re-run with `--apply`.
4. Run consumer test and snapshot suites.
5. Re-run dry-run to confirm an idempotent no-op.

## Next steps

- Update call sites to `@Suite`, `@Test`, and `#expectSnapshot(...)`
- Keep snapshot traits on the suite or test declarations
- See [Documentation/Usage.md](Documentation/Usage.md), [Documentation/Traits.md](Documentation/Traits.md), and [Documentation/Parameterised.md](Documentation/Parameterised.md) for the native forms
