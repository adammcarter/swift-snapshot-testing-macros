/**
 Open `Tests/SnapshotsIntegrationTests/ExpectSnapshot` while developing the native Swift Testing API.

 There are no integration fixtures for the deprecated `@SnapshotSuite` / `@SnapshotTest` macros.
 They expanded to non-static `@used` / `@section` properties, which Xcode 26.4 rejects, so the
 fixtures could not compile for iOS on any current toolchain — the breakage this package's native
 API exists to escape. Their macro expansion is still covered as source text by the unit tests,
 which assert the expansion without building it.
 */
