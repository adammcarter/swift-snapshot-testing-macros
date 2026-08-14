# Migration

Migrating from the deprecated `@SnapshotSuite` / `@SnapshotTest` macros to native Swift Testing
plus `#expectSnapshot(...)` is handled by a separate tool:

**https://github.com/adammcarter/swift-snapshot-testing-macros-migrator**

It lives in its own repository because it is a one-time tool — adopters run it once and never
build it again, so it does not belong in the library every consumer compiles.

```shell
git clone https://github.com/adammcarter/swift-snapshot-testing-macros-migrator
cd swift-snapshot-testing-macros-migrator
Tools/migrate-snapshot-tests --project-root /path/to/your-repo            # dry run
Tools/migrate-snapshot-tests --project-root /path/to/your-repo --apply
```

That repository's `MIGRATION.md` carries the full detail this file used to hold:

- the legacy-to-native mapping for suites, tests, `configurations:` and `configurationValues:`
- runtime requirements and semantic differences (including `record:` behaviour)
- **what changes about your reference images on macOS, and why you re-record once** — sRGB colour
  tagging, the fixed 2x unspecified scale, and theme traits now being applied per theme
- artifact naming parity, and the reference renames the tool performs alongside the source rewrite

### Re-recording references

Snapshot references are bound to the environment that rendered them — image output depends on the
Xcode **and** macOS version, not just your code. So re-record on the environment that *verifies*
them (your CI), not a developer machine that may differ, or the references will fail for everyone
else. This library records its own references on CI via a **Regenerate Snapshot References**
workflow that re-records everything on the runner and commits the result to the branch — a pattern
worth mirroring in your own repo if your contributors' machines vary. Contributing to this library
directly? See [CONTRIBUTING.md](CONTRIBUTING.md#regenerating-references-on-ci).

## Quick mapping

Kept here so the shape of the change is visible without leaving the library:

| Legacy surface | Native replacement |
| --- | --- |
| `@SnapshotSuite` | `@Suite` plus snapshot traits |
| `@SnapshotTest` | `@Test` plus `#expectSnapshot(...)` |
| `@SnapshotTest("Name")` | `@Test("Name")`, plus `named:` for snapshot artifact naming when needed |
| `@SnapshotTest(configurations: ...)` | `@Test(arguments: [SnapshotConfiguration(...)])` plus `#expectSnapshot(configuration) { ... }` |
| `@SnapshotTest(configurationValues: ...)` | `@Test(arguments: values)` plus `#expectSnapshot(argument: value) { ... }` |

For the native forms themselves see [Documentation/Usage.md](Documentation/Usage.md),
[Documentation/Traits.md](Documentation/Traits.md), and
[Documentation/Parameterised.md](Documentation/Parameterised.md).
