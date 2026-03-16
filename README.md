[![Snapshot Tests](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml/badge.svg)](https://github.com/adammcarter/swift-snapshot-testing-macros/actions/workflows/run-tests.yaml)

# Overview

`SnapshotTestingMacros` is a thin layer over [swift-testing](https://github.com/swiftlang/swift-testing) and [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to allow for macro based snapshots using a syntax similar to Swift Testing.

Just as Swift Testing has `@Suite` and `@Test`, `SnapshotTestingMacros` uses `@SnapshotSuite` and `@SnapshotTest` to mark up code.

This allows for snapshots to quickly be created by simply marking up functions that return views.

# Documentation

- [Usage](Documentation/Usage.md) - Basic usage, example code, and async support.
- [Traits](Documentation/Traits.md) - Customising snapshots with traits (sizes, themes, padding, etc.).
- [Parameterised Tests](Documentation/Parameterised.md) - Creating snapshots for multiple configurations.

# Supported views

- **SwiftUI**: Any view conforming to `View`
- **UIKit** (iOS, tvOS, visionOS): `UIView`, `UIViewController`
- **AppKit** (macOS): `NSView`, `NSViewController`


# Running tests

For detailed instructions on running tests, please see [CONTRIBUTING.md](CONTRIBUTING.md).

# Contributing

This project uses [mise](https://mise.jdx.dev) to manage development tools.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed setup and guidelines.
