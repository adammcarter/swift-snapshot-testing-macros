# Contributing

Thank you for your interest in contributing to `swift-snapshot-testing-macros`!

## Development Setup

This project uses [mise](https://mise.jdx.dev) to manage development tools and ensure consistent versions across contributors.

### Prerequisites

1.  Install `mise`: https://mise.jdx.dev/getting-started.html
2.  Clone the repository.
3.  Run `mise install` in the project root to install dependencies (like `swiftlint`).

## Running Tests

### Unit Tests
Run the unit tests using Swift Package Manager or Xcode:
```bash
mise run test
```
or
```bash
swift test
```

For faster local iteration, prefer the focused unit suites used in the cross-Xcode CI matrix:
```bash
swift test --filter ExpectSnapshotAdapterTests
swift test --filter ExpectSnapshotMacroTests
swift test --filter SnapshotSuiteTests
swift test --filter SnapshotTestTests
```

### Integration Tests
Integration tests require a specific simulator (iPhone 17, iOS 26.2) to match reference snapshots.

Run via command line:
```bash
mise run test-integration
```
or
```bash
xcodebuild test \
  -scheme SnapshotsIntegrationTests \
  -destination "platform=iOS Simulator,name=iPhone 17"
```

## Code Style

We use `swift-format` and `swiftlint` to enforce code style.

-   **Check Format**: `mise run lint` (or `./Tools/format-check`)
-   **Apply Format**: `mise run format` (or `./Tools/format`)

Please ensure `format-check` passes before submitting a Pull Request.
