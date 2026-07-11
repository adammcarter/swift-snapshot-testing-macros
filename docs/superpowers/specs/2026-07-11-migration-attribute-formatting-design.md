# Migration Attribute Formatting Design

## Goal

Migration output must leave every declaration attribute block in a predictable,
readable shape when that declaration was changed by the migration:

```swift
@MainActor
@available(iOS 17, *)
@Suite(.theme(.light))
struct CardSnapshots {}
```

Each attribute occupies its own line and no empty or whitespace-only line sits
between attributes. Comments, indentation, source line endings, and spacing
outside the attribute block remain intact.

## Scope

Normalization applies only to attribute blocks on declarations whose attributes
the migration inserts, renames, removes, or folds. It is not a general Swift
formatter and must not reformat unrelated declarations, bodies, strings, or
comments.

Comments inside an attribute block remain in their original order. They count as
content, not whitespace, so they are preserved while surrounding empty lines are
removed:

```swift
@MainActor
// Runs serialized because rendering is process-global.
@Suite(.serialized)
struct CardSnapshots {}
```

## Formatting Contract

For each migrated declaration:

1. Every attribute starts on its own line.
2. Consecutive attributes have exactly one line break between them.
3. Whitespace-only separator lines inside the attribute block are removed.
4. Existing indentation is retained for nested declarations.
5. Existing comments retain their text and relative order.
6. The source file's LF or CRLF convention is retained.
7. The declaration follows the final attribute on the next line at the same
   indentation level.
8. Running the migration again produces byte-identical output.

## TDD Matrix

Each confirmed defect is developed independently: one failing output assertion,
the smallest production change, then focused and surrounding green tests.

| Case | Required result |
|---|---|
| `@Suite` before `@SnapshotSuite` | One surviving `@Suite`; no blank line |
| `@SnapshotSuite` before `@Suite` | One surviving `@Suite`; no blank line |
| Multiple duplicate suites | One surviving `@Suite`; no accumulated newlines |
| Spaces or tabs on separator lines | Separator line removed |
| Existing `@MainActor` / `@available` | One attribute per line, contiguous block |
| Migration-inserted `@MainActor` | Inserted on its own line without extra spacing |
| Same-line source attributes | Split onto separate lines when the block is migrated |
| Comment between attributes | Comment preserved; empty surrounding lines removed |
| Nested declaration | Original indentation retained |
| CRLF source | CRLF retained throughout the changed block |
| Second migration pass | Output is byte-identical |

Tests assert exact relevant output rather than broad `contains` checks and also
verify that the rewritten Swift parses cleanly.

## Implementation Boundary

Use a syntax-aware normalization pass after semantic text edits are applied. The
pass receives the set of declarations whose attribute lists were touched and
normalizes only those attribute spans in the rewritten source. This keeps
formatting reconciliation in one place instead of spreading newline heuristics
across insertion, deletion, rename, and trait-folding edits.

The pass must operate on trivia and attribute boundaries, never by globally
replacing text matching `@` or blank lines. If a declaration cannot be mapped
safely after rewriting, leave its formatting unchanged rather than risk editing
unrelated source.

## Verification

- Run every new regression alone and observe the expected red assertion.
- Run the migration test suites after each green step.
- Run the full macOS package test plan through Xcode MCP.
- Verify migration idempotence for the formatting matrix.
- Confirm the repository has no populated use-cases matrix; if one appears,
  bind and verify the formatting behavior before sign-off.
- Push the completed branch and require PR #100 CI to pass.

## Non-goals

- Reformatting all Swift source.
- Sorting or semantically reordering attributes.
- Wrapping long attribute argument lists.
- Changing spacing inside attribute arguments.
- Removing or rewriting comments.
