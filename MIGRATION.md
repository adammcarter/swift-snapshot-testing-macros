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

## Runtime requirements and semantic differences

- `#expectSnapshot(...)` is Swift Testing only at runtime: it must run on the active Swift
  Testing test task. Calling it from an XCTest method during incremental migration, from
  `Task.detached { ... }`, or from a GCD callback that leaves the test task is unsupported —
  the assertion is skipped and a failure issue is recorded at the call site (surfaced as a
  run-level issue, since there is no test to attribute it to). Keep XCTest-hosted snapshot
  tests on the legacy pointfree `assertSnapshot` until their suite migrates to `@Test`.
- `assertSnapshot(..., record: false)` and `@Test(.record(false))` are not equivalent:
  pointfree's `record: false` behaves like `.missing` (verify existing references, record
  missing ones), while the `.record(false)` trait maps to `.never` (strictly verified — a
  missing reference fails the test and is never written). Migrate `record: false` call sites
  to `.record(.missing)` when you need to keep bootstrapping missing references; keep
  `.record(false)` when a missing reference should be a hard failure.
- A bare `#expectSnapshot(value)` inside `@Test(arguments:)` is rejected at runtime and skipped
  before rendering, even when it has `named:`. Swift Testing exposes that the case is
  parameterised but the Apple-shipped module does not expose supported argument values, so the
  runtime cannot prove an assertion label is distinct without private reflection. Use `argument:`
  or `SnapshotConfiguration`; `named:` may still label that configured assertion.
- A trait-less unnamed assertion now includes a stable source-location suffix in its reference
  name. Rename or re-record existing references once, or provide `named:` to preserve an explicit
  on-disk name. Applying any snapshot trait retains the established attempt-scoped base-name,
  `-2`, `-3`, ... ordering.

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

## macOS references recorded before v3 must be re-recorded

**If you are upgrading a macOS suite from 2.x, expect every reference image to change, and plan to re-record once.** This is by design, not a regression — but it is unavoidable, so budget for it rather than being surprised by a wall of red on the first run.

Three v3 changes each alter macOS output on their own. Any one of them is enough to make an old reference mismatch:

| Change | Effect on a 2.x reference | Why |
| --- | --- | --- |
| Colour space is tagged sRGB | **Every pixel differs**, including flat background | 2.x produced Generic RGB, which is device-dependent. sRGB is deterministic, so the same view records identically on any machine. |
| Unspecified scale is a fixed 2x | Dimensions match a 2.x reference recorded on a Retina Mac; a non-Retina one halves | 2.x followed the recording machine's screen, so references were never reproducible across machines or on CI. See [Documentation/Usage.md](Documentation/Usage.md). |
| Theme traits are applied per theme | Light references change; dark ones do not | 2.x recorded byte-identical files for `.light` and `.dark` — the theme was never applied, so every "light" reference was a duplicate of its dark twin and proved nothing. |

The colour-space change alone re-records everything, so there is no combination of renaming or configuration that preserves a 2.x macOS baseline. What the migration *does* preserve is the ability to **review** the change: references keep resolving (see naming parity below), so the first run reports real, inspectable mismatches instead of silently recording new artifacts over a baseline that no longer resolves.

Recommended once-only sequence:

1. Migrate the source and rename references so assertions resolve their existing artifacts.
2. Run the suite and read the failures as a diff of your whole baseline.
3. Spot-check a representative sample — especially any `.light` references, which were never valid under 2.x.
4. Re-record, and commit the re-recorded references as their own reviewable commit, separate from the code migration.

iOS suites are unaffected by the scale and colour-space items: they inherit a real device scale and already recorded in the device's colour space.

## Artifact naming parity

Legacy parameterised artifacts live at `__Snapshots__/<TestFile>/<case>/<display>_<size>_<theme>.<n>.<ext>`. v3 moved them to `__Snapshots__/<TestFile>/<display>/<case>_<display>_<size>_<theme>.<n>.<ext>` — the case name moved out of the folder and into the file-name prefix, and the folder became the test's display name.

Migrated tests therefore do **not** resolve 2.x references until those files are renamed into the v3 layout. A missing reference records rather than fails, so an unmigrated baseline produces a green run that compares nothing. Rename the files as part of the migration; the mapping is mechanical and derivable from the old path alone.

Once the references are in the v3 layout, naming stays stable as long as:

- the legacy display name is passed through `named:` unchanged (the migration script applies the legacy fallback chain: test display name → suite display name → function name), and
- the case naming goes through the configuration — explicit `SnapshotConfiguration(name:)` entries for `configurations:`, or `SnapshotConfiguration(name: "\(value)", value: value)` for `configurationValues:`.

Residual caveats:

- Legacy UIKit/AppKit `configurations:` declarations without unique literal case names are still skipped by the migration script (`unsupported-argument-naming`) because their legacy artifacts collided on a single path.
- Legacy SwiftUI `configurations:` entries with `name: nil` also collided on one un-suffixed artifact per size/theme; the native pipeline derives a per-case name instead, so those references must be re-recorded once after migration.
- A named `@SnapshotSuite` with two or more `@SnapshotTest` functions lacking per-test display names used to resolve every test to the same suite-named artifact (persistent false failures, or silent overwrites in record mode). The legacy runtime now disambiguates that fallback per test as `<suite display name>/<function name>`, so those previously colliding references must be re-recorded; a suite whose fallback applies to only one test keeps its original suite-named artifacts. The migration script still passes the plain legacy fallback through `named:`.
- Slash-delimited display names on parameterized tests now follow the same slash-as-subfolder convention as plain tests: `#expectSnapshot(configuration, named: "Menu/Item")` nests `Menu/Item/` under the test file's snapshot folder and names each case's artifact `<case>_Item_<size>_<theme>`. Previously the folder was flattened to `Menu-Item` and the raw `/` leaked into the reference file name (`<case>_Menu-Item_<size>_<theme>`); references recorded under that flattened layout must be moved/renamed or re-recorded once. Plain (non-parameterized) slash names are unaffected.
- Explicitly fixed sizes now embed their dimensions in the size component of the reference name: `fixed-size` became `fixed-<width>x<height>`, `min-height` became `min-height-w<width>`, `min-width` became `min-width-h<height>`, and an explicit `scale:` appends `-<scale>x`. Previously, several fixed sizes on one test were distinguishable only by the positional `.N` counter, so editing the sizes list silently re-mapped references to different geometries. References recorded under the old `fixed-size`/`min-height`/`min-width` names must be renamed or re-recorded once. The fully-minimum default keeps its `min-size` name, so default-sized references are unaffected.
- The deprecated macros now reject shapes that previously expanded into silently broken or silently missing code, with compile-time diagnostics instead: a parameterised `@SnapshotTest` without `configurations:`/`configurationValues:`, an unsupported return type, `@SnapshotTest` on a non-function declaration, an interpolated display name, `@SnapshotSuite` on an extension, and suites whose initialiser cannot be called with zero arguments (required parameters — including a required `SnapshotConfiguration` parameter, which the expansion was never actually able to pass — failable first initialisers, or stored properties without defaults). A bare `@SnapshotTest` without an enclosing `@SnapshotSuite` now warns and generates nothing instead of leaving a dead generator container behind. `@available` on a legacy test function is now copied to its generated generator container, and `configurationValues:` accepts any `Collection` (for example ranges or sets) at runtime, matching its declared signature. Migrating to `@Test` plus `#expectSnapshot(...)` remains the fix for all rejected shapes.

## Migration script

Run from a checkout of this repository:

```shell
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo --apply --json-report ./snapshot-migration-report.json
```

The command defaults to dry-run mode. Add `--apply` to write migrated files. Each run also reports total, scan, rewrite/stage, and apply timings in both the console summary and JSON report. The console summary prints at most 50 issue lines, ending with `... and N more issue(s)` when truncated; use `--json-report` for the full list.

### Command-line options

| Option | Meaning |
|---|---|
| `--project-root <path>` | Root of the project to scan. Required. |
| `--apply` | Write the migrated files. Without it the run is a dry-run and modifies nothing. |
| `--json-report <path>` | Write the full machine-readable report (including every issue line) to `<path>`. |
| `--keep-temp` | Keep the run's staging directory under `/tmp/snapshot-migration` for inspection. |
| `--fail-on-skips` | Exit with code 4 when any declaration is skipped or any file is unreadable or oversize. |
| `--max-file-size-bytes <bytes>` | Exclude files larger than `<bytes>` from migration (default: `2000000`). |
| `--max-staged-bytes <bytes>` | Fail the run when the staged rewritten copies exceed `<bytes>` in total (default: `536870912`). |
| `--apply-lock-timeout-seconds <s>` | Wait up to `<s>` seconds for another `--apply` run's lock before giving up (default: `0`). |
| `--help`, `-h` | Print usage (all options plus the exit-code ladder) and exit 0. |

Every run stages its rewritten sources under a user-private directory (`/tmp/snapshot-migration/run-<uuid>`, mode `0700`, parent included). The staging directory is removed at the end of the run — dry-run or apply, success or failure — except in two cases:

- `--keep-temp` keeps it for inspection.
- A failed `--apply` run keeps it as the recovery copy of the intended rewrites.

Whenever the directory is kept, the CLI prints `staged rewrites kept at: <path>`.

### Suite attribute handling

Legacy suites often carry both attributes (`@Suite` for Swift Testing discovery plus
`@SnapshotSuite` for the snapshot machinery). The script always leaves exactly one `@Suite`
behind:

- A bare `@Suite` is removed and `@SnapshotSuite(...)` is renamed in place, keeping its
  arguments: `@Suite` + `@SnapshotSuite(.theme(.light))` becomes `@Suite(.theme(.light))`.
- An argument-carrying `@Suite` is preserved verbatim and the legacy attribute is deleted
  instead, with its snapshot traits folded onto the surviving attribute:
  `@Suite("Cards", .serialized)` + `@SnapshotSuite(.theme(.light))` becomes
  `@Suite("Cards", .serialized, .theme(.light))`.
- A legacy display name (`@SnapshotSuite("Suite Cards", ...)`) is not promoted onto an
  argument-carrying `@Suite` — it never named the Swift Testing suite — but it still names the
  snapshot artifacts through the `named:` fallback chain described under artifact naming parity.

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
