# Native Snapshot Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the compact native snapshot coverage matrix approved after the QA audit.

**Architecture:** Preserve the macOS unit, iOS integration, and iOS three-iteration repetition targets. Add focused behavioral tests and canonical references; change production code only if a new red test exposes a defect.

**Tech Stack:** Swift 6, Swift Testing, SwiftUI, UIKit, AppKit, Point-Free SnapshotTesting, Xcode MCP, GitHub Actions.

---

### Task 1: Concurrent execution-context counters

**Files:**
- Modify: `Tests/SnapshotsUnitTests/ExpectSnapshot/SnapshotExecutionContextAttemptScopingTests.swift`
- Modify only if red exposes a defect: `Sources/SnapshotTestingMacros/Assertion/SnapshotExecutionContext.swift`

- [x] **Step 1: Write the concurrent behavioral test**

Add an async test that launches 256 child tasks against one
`SnapshotExecutionContext`. Each task requests `resolvedAssertionName(named:
"shared")` and `nextReferenceIdentifier(forKey: "shared")`. Assert that the
returned names equal `shared`, `shared-2` through `shared-256` as an unordered
set, and identifiers equal `1` through `256` as an unordered set.

- [x] **Step 2: Run the test through Xcode MCP**

Run only the two concurrent counter tests in
`SnapshotExecutionContextAttemptScopingTests`.
If it passes immediately, temporarily remove synchronization around both counters
and rerun until the assertion fails; restore the production file before continuing.

- [x] **Step 3: Make the minimum production fix if required**

Keep all mutations to `usedNames` and `referenceCounts` inside the existing
`NSLock.withLock` critical section. Do not add test-only production APIs.

- [x] **Step 4: Verify green**

Run the new test plus the complete `SnapshotContextAttemptScopingTests`,
`SnapshotExecutionContextOwnershipTests`, and
`ReferenceIdentifierAttemptScopingTests` suites through Xcode MCP.

### Task 2: Traitless source-qualified integration identity

**Files:**
- Create: `Tests/SnapshotsIntegrationTests/ExpectSnapshot/ExpectSnapshot+SourceIdentity.swift`
- Record: `Tests/SnapshotsIntegrationTests/ExpectSnapshot/__Snapshots__/ExpectSnapshot+SourceIdentity/**`

- [x] **Step 1: Write the public integration test**

Create one traitless `@Test` containing two unnamed `#expectSnapshot(Text(...))`
calls on distinct source lines. Do not add `named:` or a snapshot trait.

- [x] **Step 2: Verify red**

Run the integration scheme on the pinned iOS environment and require missing
references whose names contain the two exact source locations.

- [x] **Step 3: Record and verify canonical references**

Use the record workflow's iOS 26.2 job. The second run must pass and the recorded
files must remain distinct.

### Task 3: Native renderer trait matrix

**Files:**
- Create: `Tests/SnapshotsIntegrationTests/ExpectSnapshot/ExpectSnapshot+TraitMatrix.swift`
- Modify: `Tests/SnapshotsUnitTests/ExpectSnapshot/ExpectSnapshot+AppKitRuntimeTests.swift`
- Record: the corresponding integration and AppKit `__Snapshots__` directories

- [x] **Step 1: Write the SwiftUI composition test**

Add a light-theme minimum-size test for `.backgroundColor(.red), .padding(8)`
with an explicit name. Do not keep the reverse order when canonical artifacts
prove the runtime's normalized trait state renders it byte-identically.

- [x] **Step 2: Write UIKit fixed-size decoration test**

Snapshot `makeLabel(...)` under `.theme(.light)`, `.sizes(width: 160, height:
80)`, `.backgroundColor(.red)`, and `.padding(8)`.

- [x] **Step 3: Write UIKit recursive-description test**

Snapshot `makeLabel(...)` under `.theme(.light)` and
`.strategy(.recursiveDescription)` so the native public helper produces a text
reference.

- [x] **Step 4: Write AppKit public-helper composition test**

Add an NSView case under `.theme(.light)`, `.sizes(width: 160, height: 80)`,
`.backgroundColor(.red)`, and `.padding(8)`.

- [x] **Step 5: Verify red, record, and verify green**

Run the affected schemes first without references, then use the pinned record
workflow and require its second run to pass.

### Task 4: Child-task repetition

**Files:**
- Modify: `Tests/SnapshotsIntegrationRepetitionTests/ExpectSnapshotRepetitionTests.swift`
- Record: `Tests/SnapshotsIntegrationRepetitionTests/__Snapshots__/ExpectSnapshotRepetitionTests/**`

- [x] **Step 1: Write the awaited child-task test**

Add an async test that awaits `Task { #expectSnapshot(Text("child task")) }.value`
inside the existing trait-scoped suite. Keep execution sequential; concurrent
unnamed assertions are deliberately nondeterministic.

- [x] **Step 2: Verify red**

Run the three-iteration plan and require a missing reference on the first attempt,
without drift to `-2` or `.2` on later attempts.

- [x] **Step 3: Record and verify canonical reference**

Use the pinned repetition record job and require the verification run to pass all
three iterations against one stable reference.

### Task 5: Final verification and history

**Files:**
- Verify all files changed by Tasks 1-4

- [x] **Step 1: Run focused Xcode MCP tests**

Run all new unit tests and list every expected/pass/fail count.

- [x] **Step 2: Run formatting and lint**

Run the repository formatting and SwiftLint gates against all changed Swift files.

- [ ] **Step 3: Run the full test workflow**

Require the macOS unit, iOS integration, iOS repetition, Swift-version matrix,
native-consumer, and lint jobs to complete with zero unexpected failures.

- [ ] **Step 4: Check acceptance records**

Run `matrix.validate`; because the repository has no populated use-cases matrix,
report that fact and do not scaffold one.

- [ ] **Step 5: Commit and push**

Amend or commit logical test slices, push `snapshot-helpers`, and leave PR #100
unmerged for user sign-off.
