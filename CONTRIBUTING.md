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
Integration tests render against committed references, so run them on the same Xcode CI records
on. That toolchain and the simulator destination are defined once in `mise.toml` (`[env]`), so use
the mise task rather than a hand-written `xcodebuild` line — it always uses the single source:

```bash
mise run test-integration
```

## Code Style

We use `swift-format` and `swiftlint` to enforce code style.

-   **Check Format**: `mise run lint` (or `./Tools/format-check`)
-   **Apply Format**: `mise run format` (or `./Tools/format`)

Please ensure `format-check` passes before submitting a Pull Request.
