# Migration Overlapping Edits and Whitespace Preservation Design

## Goal

Prevent snapshot migration from corrupting source when a generated insertion overlaps an attribute deletion, while preserving all whitespace outside the exact legacy syntax being migrated.

## User-visible contract

- Migration may rename, remove, merge, or insert migration-owned attributes.
- Migration must not alter import text or attach generated text to an import.
- Existing whitespace before the first migrated attribute is preserved byte-for-byte. This includes zero, one, or multiple line breaks and whitespace-only lines after `@testable import`.
- Attribute formatting remains normalized inside a migrated attribute block: each attribute occupies its own line and whitespace-only separator lines between those attributes are removed.
- A source containing both bare `@Suite` and argument-carrying `@SnapshotSuite` produces exactly one migrated `@Suite(...)` and, when required, exactly one `@MainActor`.
- Rewriting already-migrated output is idempotent and the output parses successfully.

## Root cause

The rewriter currently applies edits in descending source-offset order against a string that has already been mutated. That works only for disjoint edits. In the reported case, the `@MainActor` insertion point lies inside the range deleting a bare `@Suite`. Applying the insertion first changes the string length; applying the enclosing deletion with original offsets then removes only part of `@MainActor`, leaving `ctor`, while the original suite attribute survives and is duplicated by the `@SnapshotSuite` rename.

## Design

The central semantic edit application path will compose overlapping edits before modifying the source. An insertion nested within a deletion or replacement is preserved at its original logical position while the original text covered by the enclosing edit is removed or replaced. Unsupported ambiguous overlaps between two non-empty ranges will fail closed during development rather than silently emitting corrupt source.

Whitespace outside an edit range is never reconstructed or normalized by this layer. The existing migrated-attribute formatter remains responsible only for layout inside blocks it knows were migrated. This separation preserves import-boundary whitespace while retaining the established one-attribute-per-line formatting contract.

## Alternatives rejected

1. Retarget `@MainActor` specifically to `@SnapshotSuite`. This fixes the reported shape but couples independent rewrite rules and leaves future nested edits corruptible.
2. Repair malformed output in the formatter. This would mask semantic corruption after it occurs and cannot reliably distinguish original user text from damaged generated text.
3. Reparse between every rewrite phase. This is broader, slower, and complicates reason and offset tracking without being necessary for deterministic edit composition.

## TDD and acceptance coverage

The first regression uses the reported combination: `@testable import`, bare `@Suite`, argument-carrying `@SnapshotSuite`, and a snapshot function requiring `@MainActor`. It must initially fail by showing the current `ConsumerAppctor`/duplicate-suite corruption.

Additional parameterized variants cover preserved import-boundary whitespace:

- no whitespace between import and the first attribute;
- one line break;
- one blank line;
- multiple blank and whitespace-only lines;
- CRLF input where supported by the existing migration contract.

Each variant asserts exact preservation of the original boundary, exactly one migrated suite attribute, exactly one required main-actor attribute, clean parsing, and idempotence. Verification then runs the focused regression suite, the full migration test surface, and the repository's keyless use-cases loop when a matrix is present.

## Scope

This change is limited to semantic edit composition and migration regressions. It does not change unrelated Swift formatting, native snapshot behavior, or public macro APIs.
