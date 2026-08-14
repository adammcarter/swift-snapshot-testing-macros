[![Snapshot Tests](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml/badge.svg)](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml)

# SnapshotTestingMacros

`SnapshotTestingMacros` adds snapshot assertions and snapshot-specific traits to [Swift Testing](https://github.com/swiftlang/swift-testing) while continuing to use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) as the snapshot engine under the hood.

The preferred API is native Swift Testing:

- `@Suite`
- `@Test`
- `#expectSnapshot(...)`
- Snapshot traits such as `.theme(...)`, `.sizes(...)`, `.padding(...)`, `.record(...)`, and `.strategy(...)`

The legacy `@SnapshotSuite` and `@SnapshotTest` macros remain available as a migration surface, but they are deprecated.

## Quick start

```swift
import SnapshotTestingMacros
import SwiftUI
import Testing

@MainActor
@Suite(.theme(.all), .sizes(.minimum))
struct ProfileCardSnapshots {
  @Test
  func profileCard() {
    #expectSnapshot(ProfileCard())
  }
}
```

`@MainActor` on the suite is worth adding from the start. A SwiftUI `View`'s initialiser is
main-actor isolated, so constructing one inside a non-isolated test produces
`call to main actor-isolated initializer … in a synchronous nonisolated context` warnings under
Swift 6. Snapshots always render on the main actor regardless; the annotation just stops the
compiler pointing it out at every call site.

### Running under xcodebuild

`swift test` needs nothing special. Building through `xcodebuild` does:

```shell
xcodebuild test -scheme YourScheme -destination 'platform=macOS' -skipMacroValidation
```

Without `-skipMacroValidation`, xcodebuild refuses to expand the macro until it has been
approved — *"Macro 'SnapshotsMacros' … must be enabled before it can be used"*. Locally that is
a **Trust & Enable** prompt in Xcode. On CI there is nobody to click it, so the flag is required
rather than optional.

## Supported platforms

iOS 15+ and macOS 15+ only. watchOS, tvOS, and visionOS are not supported; building the package for those platforms fails with an explicit compile-time error.

## Supported native surface

| Surface | Support |
| --- | --- |
| SwiftUI | Direct-value snapshots, `named:`, closure forms, `SnapshotConfiguration`, and `argument:` helpers |
| UIKit / AppKit | Direct values plus sync, throwing, async, and async-throwing closure, `SnapshotConfiguration`, and `argument:` snapshots for views and view controllers |

UIKit and AppKit builders are main-actor isolated. Use `try #expectSnapshot(try makeView())` when a direct
view/controller factory throws; throwing builders rethrow their factory and snapshot-pipeline errors.

For UIKit and AppKit, keep the test itself as a regular `@Test` unless using an async builder, and pass a
helper-backed expression such as `#expectSnapshot(makeViewController())`. Parameterised builders use
`argument:` or `SnapshotConfiguration` in the same way as SwiftUI.

## Documentation

- [Usage](Documentation/Usage.md)
- [Traits](Documentation/Traits.md)
- [Parameterised tests](Documentation/Parameterised.md)
- [Migration](MIGRATION.md)

## Migration

Adopters moving from `@SnapshotSuite` / `@SnapshotTest` to native `@Suite` / `@Test` / `#expectSnapshot(...)` should use the migrator, which lives in its own repository because it is a one-time tool:

**[swift-snapshot-testing-macros-migrator](https://github.com/adammcarter/swift-snapshot-testing-macros-migrator)**

```shell
git clone https://github.com/adammcarter/swift-snapshot-testing-macros-migrator
cd swift-snapshot-testing-macros-migrator
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo            # dry run
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo --apply
```

It rewrites the sources and renames the checked-in references in the same run. See [MIGRATION.md](MIGRATION.md) for the mapping, and that repository for the full guide — in particular what changes about macOS reference images and why you re-record once.

## Development

For local setup and detailed contributor guidance, see [CONTRIBUTING.md](CONTRIBUTING.md).

Common commands:

```shell
mise run lint
swift test
```

For fast local iteration, prefer the focused unit suites CI also uses across Xcode versions:

```shell
swift test --filter ExpectSnapshotAdapterTests
swift test --filter ExpectSnapshotMacroTests
swift test --filter SnapshotSuiteTests
swift test --filter SnapshotTestTests
```

```shell
xcodebuild test \
  -scheme SnapshotsUnitTests \
  -destination 'platform=macOS'
```

Integration tests render against committed references, so the Xcode and simulator destination are
pinned once in `mise.toml`; run them through the mise task so they always use that single source:

```shell
mise run test-integration
```

Snapshot references are bound to the recording environment (Xcode **and** macOS), so if your machine
differs from CI you cannot produce matching references locally. Instead, run the **Regenerate
Snapshot References** workflow (Actions → Run workflow) on your branch — it re-records everything on
the CI runner and commits the result onto your branch. See
[CONTRIBUTING.md](CONTRIBUTING.md#regenerating-references-on-ci) for the full flow.

Latest-Xcode CI also runs fast macOS build-for-testing smoke checks on 26.4 and 26.5:

```shell
xcodebuild build-for-testing \
  -scheme SnapshotsUnitTests \
  -destination 'platform=macOS'

xcodebuild build-for-testing \
  -scheme SnapshotsIntegrationTests \
  -destination 'platform=macOS'
```
