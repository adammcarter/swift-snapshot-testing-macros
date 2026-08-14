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

### Snapshot references and the recording environment
Snapshot references are pixel-exact and **bound to the environment that rendered them** — image
rendering depends on the toolchain *and* the OS, not just your code. CI is the source of truth,
and it records with a fixed environment declared once in `mise.toml` (`[env]`):

| Variable | Value | Selectable? |
| --- | --- | --- |
| `SNAPSHOT_XCODE` | Xcode version | Yes — pinned, and `setup-xcode` selects it |
| `SNAPSHOT_MACOS` | macOS version references were recorded on | **No** — set by GitHub's `macos-26` runner image |

To reproduce references **locally you need both**: the same Xcode *and* the same macOS. Matching
only Xcode is not enough — AppKit/`NSTextField` text rasterises differently across macOS point
releases, so a machine on a different macOS will see AppKit snapshot diffs even with the right
Xcode. When your machine differs from CI, don't commit local renders — regenerate on CI.

The `Snapshot Environment` CI job warns when the runner drifts from either value; a macOS drift
means GitHub bumped the runner and references need re-recording (bump `SNAPSHOT_MACOS` then).

### Regenerating references on CI

When references need updating — you changed something that alters rendering, or the runner's macOS
moved — don't record locally if your machine differs from CI. Instead, from your branch:

1. Push your branch.
2. **Actions → Regenerate Snapshot References → Run workflow → pick your branch.**
3. It clears every reference (via `Tools/remove-snapshots`, so deleted or renamed tests drop their
   orphans), re-records every suite on the CI runner, bumps `SNAPSHOT_MACOS` to that runner's
   macOS, and **commits the result straight onto your branch**. It refuses the default branch —
   references reach it through your normal PR.
4. `git pull`, then re-run your PR's checks (a bot push does not re-trigger them automatically).

Your local macOS never matters; you only review the committed diff.

### Integration Tests
The toolchain and the simulator destination are defined once in `mise.toml` (`[env]`), so use the
mise task rather than a hand-written `xcodebuild` line — it always uses the single source:

```bash
mise run test-integration
```

## Code Style

We use `swift-format` and `swiftlint` to enforce code style.

-   **Check Format**: `mise run lint` (or `./Tools/format-check`)
-   **Apply Format**: `mise run format` (or `./Tools/format`)

Please ensure `format-check` passes before submitting a Pull Request.
