# Migration Attribute Formatting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every migrated declaration's attribute block use one attribute per line with no blank or whitespace-only separator lines, while preserving comments, indentation, line endings, unrelated source, and idempotence.

**Architecture:** Apply semantic migration edits first, then map the original keyword offsets of only the declarations whose attributes changed into the rewritten source. A focused SwiftSyntax formatter reparses that output and rebuilds only those matched attribute spans from exact attribute source slices plus normalized trivia separators; it fails closed when conditional/non-attribute elements make a block unsafe to rebuild.

**Tech Stack:** Swift 6.1/6.2, SwiftSyntax 602, SwiftParser, Swift Testing, Xcode MCP.

---

## File Map

- Create `Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift`: syntax-aware, touched-range-only formatting pass.
- Create `Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift`: exact black-box migration-output regressions.
- Modify `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift`: collect touched declaration keyword offsets, remap them through semantic edits, and invoke the formatter.

### Task 1: Prove whitespace-only attribute separators are currently retained

**Files:**
- Create: `Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift`

- [ ] **Step 1: Add the first exact-output regression**

```swift
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotMigrationRewriterAttributeFormattingTests {
  @Test
  func removesWhitespaceOnlyLinesInsideMigratedAttributeBlock() throws {
    let input = """
    @MainActor
       
    @SnapshotSuite(.theme(.light))
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite(.theme(.light))
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }
}
```

- [ ] **Step 2: Run only this test with Xcode MCP**

Switch `windowtab26` to scheme `SnapshotsUnitTests`, discover the test identifier with `GetTestList`, then run it with `RunSomeTests`.

Expected: one assertion failure showing `@MainActor\n   \n@Suite` in the actual output.

- [ ] **Step 3: Confirm the failure is formatting-only**

Expected: `result.reasons.isEmpty`, rewritten Swift parses, and the failed comparison differs only by the whitespace-only separator line.

### Task 2: Add the touched-declaration formatting seam

**Files:**
- Create: `Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift`
- Modify: `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift:69-164`
- Modify: `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift:1359-1480`

- [ ] **Step 1: Track suite and successfully rewritten function keywords**

Add `suiteDeclarationKeywordOffsets` to `RewriteCollector` and `RewriteCollectorVisitor`. Pass each struct/class/actor/enum keyword offset into `removeDuplicateSuiteAttributeIfNeeded`; when the attribute list contains an unqualified `@SnapshotSuite`, record that offset even when no duplicate `@Suite` exists.

In `rewrite(source:)`, insert the function keyword offset into a local `Set<Int>` only when `functionEdits` is non-nil, then union it with the collector's suite offsets.

```swift
var touchedDeclarationKeywordOffsets = collector.suiteDeclarationKeywordOffsets

if let functionEdits {
  edits.append(contentsOf: functionEdits)
  touchedDeclarationKeywordOffsets.insert(
    legacyFunction.function.funcKeyword.positionAfterSkippingLeadingTrivia.utf8Offset
  )
}
```

- [ ] **Step 2: Remap original keyword offsets through semantic edits**

Add a private helper beside `apply(edits:to:)`:

```swift
private func outputUTF8Offset(forOriginalOffset offset: Int, after edits: [TextEdit]) -> Int {
  offset + edits.reduce(into: 0) { delta, edit in
    guard edit.endUTF8Offset <= offset else { return }
    delta += edit.replacement.utf8.count - (edit.endUTF8Offset - edit.startUTF8Offset)
  }
}
```

After semantic edits are applied, map the touched offsets and format only those declarations:

```swift
let semanticOutput = apply(edits: edits, to: source)
let outputKeywordOffsets = Set(
  touchedDeclarationKeywordOffsets.map {
    outputUTF8Offset(forOriginalOffset: $0, after: edits)
  }
)
let output = MigratedAttributeBlockFormatter().format(
  source: semanticOutput,
  declarationKeywordOffsets: outputKeywordOffsets
)
```

- [ ] **Step 3: Implement the focused formatter**

`MigratedAttributeBlockFormatter` reparses `semanticOutput`. Its visitor handles `StructDeclSyntax`, `ClassDeclSyntax`, `ActorDeclSyntax`, `EnumDeclSyntax`, and `FunctionDeclSyntax`; it compares each declaration keyword's UTF-8 offset against the supplied set.

For a matched declaration:

1. Require a non-empty attribute list containing only `AttributeSyntax` elements; otherwise emit no edit.
2. Slice each attribute exactly from `positionAfterSkippingLeadingTrivia` through `endPositionBeforeTrailingTrivia`.
3. Slice each separator through the next attribute or the first modifier/declaration keyword.
4. Remove whitespace-only separator lines, preserve comment-bearing lines and inline trailing comments, and finish every separator with the file's detected `\n` or `\r\n` plus declaration indentation.
5. Rebuild only the range from the first `@` through the token following the attribute list; apply collected edits from highest offset to lowest.

Use a private formatter-local edit type so `TextEdit` remains encapsulated in the rewriter.

- [ ] **Step 4: Run the first regression again**

Expected: 1 passed, 0 failed; the exact prefix is contiguous and parses cleanly.

- [ ] **Step 5: Run the existing suite-dedup regressions**

Run these existing identifiers with Xcode MCP:

- `dedupingSuiteAttributesKeepsAdjacentAttributeLinesTogether()`
- `preservesExistingSuiteArgumentsWhenDedupingAgainstSnapshotSuite()`
- `deletesBareSnapshotSuiteWhenExistingSuiteHasArguments()`
- `foldsTraitsWhenSnapshotSuitePrecedesArgfulSuite()`

Expected: 4 passed, 0 failed.

- [ ] **Step 6: Commit and push the first red-green slice**

```bash
git add Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift \
  Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift \
  Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift
git commit -m "fix: normalize migrated attribute blocks"
git push origin snapshot-helpers
```

Do not stage `Tests/SnapshotsUnitTests/ExpectSnapshot/SnapshotExecutionContextAttemptScopingTests.swift`; it is unrelated concurrent work.

### Task 3: Probe attribute ordering, duplicates, and same-line forms one case at a time

**Files:**
- Modify: `Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift`
- Modify only if a new red requires it: `Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift`

- [ ] **Step 1: Add and run `normalizesSnapshotSuiteBeforeExistingSuite()`**

Input prefix:

```swift
@MainActor
@SnapshotSuite(.sizes(.minimum))

@Suite("Cards")
struct CardSnapshots
```

Expected exact prefix:

```swift
@MainActor
@Suite("Cards", .sizes(.minimum))
struct CardSnapshots
```

- [ ] **Step 2: Add and run `collapsesMultipleDuplicateSuiteSeparators()`**

Input uses `@Suite`, a whitespace-only line, another bare `@Suite`, and `@SnapshotSuite(.theme(.dark))`. Expected output contains one `@Suite(.theme(.dark))` directly below `@MainActor`.

- [ ] **Step 3: Add and run `splitsSameLineAttributesWhenBlockIsMigrated()`**

Input prefix:

```swift
@MainActor @SnapshotSuite
struct CardSnapshots
```

Expected prefix:

```swift
@MainActor
@Suite
struct CardSnapshots
```

- [ ] **Step 4: For each failing test, make only the smallest separator reconstruction change and rerun it**

Do not broaden formatting to declarations whose keyword offset is absent from the touched set. If a test passes immediately, keep it as characterization coverage and make no production change for that case.

- [ ] **Step 5: Run all attribute-formatting tests and commit**

Expected: every test in `SnapshotMigrationRewriterAttributeFormattingTests` passes.

```bash
git add Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift \
  Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift
git commit -m "test: cover migrated attribute layout variants"
git push origin snapshot-helpers
```

### Task 4: Preserve comments, indentation, CRLF, and idempotence

**Files:**
- Modify: `Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift`
- Modify only for confirmed reds: `Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift`

- [ ] **Step 1: Add and run `preservesCommentsWhileRemovingBlankAttributeSeparators()`**

Use a standalone line comment between `@MainActor` and `@SnapshotSuite`, surrounded by whitespace-only lines. Expect the exact block `@MainActor`, comment, `@Suite` with no blank lines.

- [ ] **Step 2: Add and run `preservesTrailingAttributeComment()`**

Use `@MainActor // UI rendering` followed by a blank line and `@SnapshotSuite`. Expect the trailing comment to remain inline and `@Suite` on the next line.

- [ ] **Step 3: Add and run `retainsNestedDeclarationIndentation()`**

Place the migrated suite inside an enum with four-space indentation. Expect every attribute and the nested `struct` keyword to retain exactly four spaces.

- [ ] **Step 4: Add and run `retainsCRLFInMigratedAttributeBlock()`**

Build input with explicit `\r\n` separators and assert the exact migrated prefix:

```swift
let expectedPrefix = "@MainActor\r\n@Suite\r\nstruct CardSnapshots"
#expect(result.output.hasPrefix(expectedPrefix))
```

- [ ] **Step 5: Add and run `isIdempotentAfterAttributeNormalization()`**

Rewrite an anomalously spaced input twice and assert:

```swift
let first = try SnapshotMigrationRewriter().rewrite(source: input)
let second = try SnapshotMigrationRewriter().rewrite(source: first.output)
#expect(second.output == first.output)
#expect(!second.changed)
```

- [ ] **Step 6: Make minimal fixes per red, run the whole formatting suite, and commit**

Expected: comment text/order, indentation, CRLF, parsing, and idempotence are all green.

```bash
git add Sources/SnapshotMigrationSupport/Rewriting/MigratedAttributeBlockFormatter.swift \
  Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterAttributeFormattingTests.swift
git commit -m "fix: preserve attribute trivia during migration formatting"
git push origin snapshot-helpers
```

### Task 5: Verify the migration surface and PR

**Files:**
- No production changes unless verification exposes a regression.

- [ ] **Step 1: Run all migration rewriter tests with Xcode MCP**

Use `GetTestList` to select all enabled tests whose path is under `Tests/SnapshotsUnitTests/Migration/`, then run them with `RunSomeTests`.

Expected: 0 failures.

- [ ] **Step 2: Run the full macOS package plan with Xcode MCP**

Switch to `swift-snapshot-testing-macros-Package` and run `RunAllTests` on `My Mac`.

Expected: 0 unexpected failures; report exact totals including expected failures/skips/not-run.

- [ ] **Step 3: Check acceptance records**

Run `matrix.validate`. If `populated: false`, report that no use-cases matrix exists and do not scaffold one. If populated, bind this behavior, run the local verification loop, and require `VERIFIED_LOCAL`.

- [ ] **Step 4: Verify worktree and diff hygiene**

```bash
git diff --check
git status --short
git diff origin/main...HEAD -- Sources/SnapshotMigrationSupport/Rewriting \
  Tests/SnapshotsUnitTests/Migration docs/superpowers
```

Expected: no whitespace errors; the unrelated modified snapshot-execution test remains unstaged and unchanged by this work.

- [ ] **Step 5: Push and monitor PR #100 CI to completion**

Push the final valuable commit, identify the run whose head SHA equals `snapshot-helpers`, and require format/lint, all Swift/Xcode matrix jobs, unit tests, iOS integration/repetition tests, and native-consumer builds to pass.
