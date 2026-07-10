# Migration

The preferred API is now native Swift Testing plus `#expectSnapshot(...)`.

The legacy `@SnapshotSuite` and `@SnapshotTest` macros are still available for migration, but they are deprecated.

## Quick mapping

| Legacy surface | Native replacement |
| --- | --- |
| `@SnapshotSuite` | `@Suite` plus snapshot traits |
| `@SnapshotTest` | `@Test` plus `#expectSnapshot(...)` |
| `@SnapshotTest("Name")` | `@Test("Name")` for test output, plus `named:` for snapshot artifact naming when needed |
| `@SnapshotTest(configurations: ...)` | `@Test(arguments: [SnapshotConfiguration(...)])` plus `#expectSnapshot(configuration) { ... }` on all platforms |
| `@SnapshotTest(configurationValues: ...)` | `@Test(arguments: values)` plus `#expectSnapshot(argument: value) { ... }`, or `#expectSnapshot(SnapshotConfiguration(name: "\(value)", value: value)) { ... }` when existing references must keep their exact legacy case names |

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

`argument:` derives the case name from the value (normalised, with a `snapshot` fallback when the
value has no usable text). When you need the artifact names to stay byte-identical to the legacy
`"\(value)"` stringification — for example, to keep checked-in references — build the
configuration explicitly, which is the form the migration script emits:

```swift
@Test(arguments: makeUserStates())
func userProfile(state: UserState) {
  let snapshotConfiguration = SnapshotConfiguration(name: "\(state)", value: state)
  let snapshotValue = UserProfileView(state: state)
  #expectSnapshot(snapshotConfiguration, named: "userProfile") { _ in snapshotValue }
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

Parameterised UIKit and AppKit snapshots use the same `SnapshotConfiguration` closure form as SwiftUI; the closure builds the platform view or controller on the main actor:

```swift
@MainActor
@Test(arguments: [
  SnapshotConfiguration(name: "compact", value: CardState.compact),
  SnapshotConfiguration(name: "expanded", value: CardState.expanded),
])
func card(configuration: SnapshotConfiguration<CardState>) {
  let snapshotConfiguration = configuration
  let state = configuration.value
  let snapshotValue: UIViewController = makeController(state: state)
  #expectSnapshot(snapshotConfiguration, named: "Card") { _ in snapshotValue }
}
```

The `argument:` convenience builder remains SwiftUI-only in v1.

## Artifact naming parity

Legacy parameterised artifacts live at `__Snapshots__/<TestFile>/<display>/<case>_<display>_<size>_<theme>.<n>.<ext>`. The native configuration pipeline produces exactly that layout, so migrated parameterised tests keep resolving the checked-in legacy references as long as:

- the legacy display name is passed through `named:` unchanged (the migration script applies the legacy fallback chain: test display name → suite display name → function name), and
- the case naming goes through the configuration — explicit `SnapshotConfiguration(name:)` entries for `configurations:`, or `SnapshotConfiguration(name: "\(value)", value: value)` for `configurationValues:`.

Residual caveats:

- Legacy UIKit/AppKit `configurations:` declarations without unique literal case names are still skipped by the migration script (`unsupported-argument-naming`) because their legacy artifacts collided on a single path.
- Legacy SwiftUI `configurations:` entries with `name: nil` also collided on one un-suffixed artifact per size/theme; the native pipeline derives a per-case name instead, so those references must be re-recorded once after migration.

## Migration script

Run from a checkout of this repository:

```shell
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo --apply --json-report ./snapshot-migration-report.json
```

The command defaults to dry-run mode. Add `--apply` to write migrated files. Each run also reports total, scan, rewrite/stage, and apply timings in both the console summary and JSON report.

Every run stages its rewritten sources under a user-private directory (`/tmp/snapshot-migration/run-<uuid>`, mode `0700`, parent included). The staging directory is removed at the end of the run — dry-run or apply, success or failure — except in two cases:

- `--keep-temp` keeps it for inspection.
- A failed `--apply` run keeps it as the recovery copy of the intended rewrites.

Whenever the directory is kept, the CLI prints `staged rewrites kept at: <path>`.

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success. |
| 1 | Migration failure (rewrite/staging failures), and the fallback for a JSON report write failure after an otherwise-successful run. |
| 2 | Apply safety failure: an apply precondition, atomic replace, or non-regular-file check failed — or the apply lock could not be acquired (even when nothing was pending to apply). |
| 3 | Invalid usage (bad or missing command-line options). |
| 4 | Strict skip failure (`--fail-on-skips` with skipped, unreadable, or oversize files). |

If `--json-report` is given and the report cannot be written after the run has finished, the CLI prints to stderr whether files were changed (for `--apply` runs, that changes WERE applied) and exits nonzero: at least 1 (`migration failure`), preserving any more severe exit code the run itself resolved. A report-write failure is never reported as invalid usage (3).

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
