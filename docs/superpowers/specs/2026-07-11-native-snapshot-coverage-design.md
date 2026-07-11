# Native Snapshot Coverage Design

## Goal

Close the high-value coverage gaps found by the `cowork:qa` audit without
restoring the deleted legacy combinatorial integration suite.

The change proves the public `#expectSnapshot` behavior at the boundaries where
unit coverage alone is insufficient: on-disk source-qualified names, renderer
trait composition, platform-specific public helpers, and repetition-scoped child
tasks. It also stress-tests the shared naming counters under concurrency.

## Architecture

Keep the existing three-layer test architecture:

```text
SnapshotsUnitTests (macOS)
  -> helper semantics, AppKit runtime, counter concurrency

SnapshotsIntegrationTests (iOS 26.2)
  -> native public helper golden images and recursive descriptions

SnapshotsIntegrationRepetitionTests (iOS 26.2, three fixed iterations)
  -> attempt reset and child-task context inheritance
```

No production API or implementation change is planned. If a new test exposes a
real defect, production code changes only after that test has failed for the
expected behavioral reason.

## Focused Matrix

| Surface | New proof | Why it is valuable |
|---|---|---|
| Traitless identity | Two unnamed public macro calls create distinct `L<line>C<column>` references | Pins the new on-disk contract, not only the in-memory resolver |
| SwiftUI composition | Background-then-padding and padding-then-background | Preserves the renderer-order variation previously covered by legacy integration fixtures |
| UIKit composition | Public UIView helper with padding, background, and fixed size | Connects native helper overloads to UIKit decoration and sizing |
| Strategy | Public UIKit helper using `.recursiveDescription` | Proves the textual renderer through the native helper path |
| AppKit composition | Public NSView helper with padding, background, and fixed size | Connects AppKit renderer internals to the public macro |
| Child-task repetition | An awaited child task snapshots during every one of three attempts | Proves task-local context inheritance and attempt reset through the real runner |
| Concurrent counters | Many child tasks request one name/key concurrently | Proves unique names and identifiers without asserting nondeterministic order |

## TDD Contract

Each golden integration slice is red when its reference artifact is absent. The
test source is added first, the focused suite is run to show the missing-reference
failure, then references are recorded on the pinned CI renderer and the same suite
must pass against them.

The concurrent counter case is coverage for existing lock-based behavior. It is
written before any production change and validated against a deliberately unsafe
mutation if it passes immediately, proving the test detects lost synchronization.
The mutation is discarded and never committed.

## Reference Ownership

- iOS images and recursive descriptions are recorded only on the workflow's
  iPhone 17 / iOS 26.2 destination.
- AppKit references are recorded only on the workflow's pinned macOS 26 runner.
- Local Xcode 27 rendering must not overwrite either canonical reference set.
- The existing `record-snapshots.yaml` workflow records every affected scheme
  twice: record missing references, then verify them.

## Acceptance

- Every new test is observed red before its reference or implementation fix.
- The concurrent test has mutation evidence when the unmodified implementation
  already passes.
- Focused unit tests pass through Xcode MCP.
- The three snapshot schemes pass on the pinned GitHub workflow.
- Full PR CI passes on the final commit.
- The branch remains clean and pushed.
- The repository has no populated use-cases matrix; do not scaffold one.

## Non-goals

- Restoring every deleted legacy SnapshotSuite/SnapshotTest permutation.
- Exhaustively combining every trait with every platform.
- Promising deterministic ordering for concurrent unnamed assertions.
- Re-recording references with local Xcode 27 renderers.
