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

@Suite(.theme(.all), .sizes(.minimum))
struct ProfileCardSnapshots {
  @Test
  func profileCard() {
    #expectSnapshot(ProfileCard())
  }
}
```

## Supported native surface

| Surface | Support |
| --- | --- |
| SwiftUI | Direct-value snapshots, `named:`, closure forms, `SnapshotConfiguration`, and `argument:` helpers |
| UIKit / AppKit | Direct-value snapshots for `UIView` / `NSView` and `UIViewController` / `NSViewController` |

In v1, the convenience builder forms are SwiftUI-only. UIKit and AppKit callers should build the view or controller first and then pass it to the direct-value `#expectSnapshot(...)` overload.

For UIKit and AppKit, keep the test itself as a regular `@Test` and pass a helper-backed expression such as `#expectSnapshot(makeViewController())`. The helper expression is evaluated on the main actor inside the snapshot operation.

## Documentation

- [Usage](Documentation/Usage.md)
- [Traits](Documentation/Traits.md)
- [Parameterised tests](Documentation/Parameterised.md)
- [Migration](MIGRATION.md)

## Migration script

This repository includes a migration helper for adopters moving from `@SnapshotSuite` / `@SnapshotTest` to native `@Suite` / `@Test` / `#expectSnapshot(...)`.

```shell
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo
Tools/migrate-snapshot-tests --project-root /path/to/consumer-repo --apply --json-report ./snapshot-migration-report.json
```

It defaults to dry-run mode and prints a summary of migrated, skipped, and failed declarations. Use `--apply` to write changes.

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

```shell
xcodebuild test \
  -scheme SnapshotsIntegrationTests \
  -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2,arch=arm64"
```

Latest-Xcode CI also runs fast macOS build-for-testing smoke checks on 26.4 and 26.5:

```shell
xcodebuild build-for-testing \
  -scheme SnapshotsUnitTests \
  -destination 'platform=macOS'

xcodebuild build-for-testing \
  -scheme SnapshotsIntegrationTests \
  -destination 'platform=macOS'
```
