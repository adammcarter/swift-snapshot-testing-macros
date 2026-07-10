# Audit round 3: migration-controlflow

Focused follow-up on the TRAIN-3 migration-lane fixes only (commits `4454fc9..ae20b04`),
reviewed by static reading of `SnapshotMigrationRewriter.swift`, `MigrationRunner.swift`,
and `MigrationReport.swift`. No tracked files were modified.

The runner accounting fix (`3bb12d3`) and the dead exit-code branch removal (`ae20b04`)
are correct: `failed`/`migrated`/`skipped` stay disjoint and sum to
`candidateDeclarations`, `migrationPercentage` reflects applied work, and the
`hadMigrationFailures => failedDeclarations > 0 => non-success exit` invariant holds —
both increment sites (lines 119-120 and 178-179) only ever increment `failedDeclarations`
and it is never decremented. The config control-flow typing fix (`1fb086f`) and the
display-name/trait fold fix (`068a0a7`) each leave one genuine but niche gap. Both are
low severity: unusual input shapes, and for the second finding a narrow coexisting-`@Suite`
dedup path.

---

## Finding 1 — Control-flow descent misses do/catch and labeled statements, defeating the unsupported-configuration-shape safety net

- **Severity:** low
- **File:** `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift:891`
- **needs_dynamic_verification:** true

**Failure scenario**

The train-3 fix (`1fb086f`) extended `collectConfigurationResultExpressions` to descend
through `return` / `guard` / `if` / `switch` / ternary so element-position `.init(...)`
config shorthands reachable via control flow are typed, and added
`configurationsExpressionHasUnsupportedInitShorthand` as a safety net that records a skip
for anything it cannot type. But the descent only recognizes `ReturnStmt`, `GuardStmt`,
`ExpressionStmt`-wrapped or bare `if`/`switch` expressions, and the final expression. A
`DoStmtSyntax` (do/catch) or a `LabeledStmtSyntax` (e.g. `outer: if ... { return .init(...) }`)
matches none of these: at lines 913-921 `statement.item.as(ExpressionStmtSyntax.self)` is
nil and `statement.item.as(ExprSyntax.self)` is nil, so `guard let expression else { continue }`
drops the entire sub-tree.

The `.init(name:...)` leaves inside a do/catch or labeled branch are therefore surfaced by
neither the rewriter (`rewriteConfigurationElementInitializers`) nor the safety-net check
(both call the same `configurationElementExpressions`). Because the safety net is only as
complete as that collector, an element it never surfaces produces NO skip AND NO typing —
so `--apply` emits the bare `.init(...)` unchanged against the rewritten
`(configuration: SnapshotConfiguration<T>)` signature: non-compiling output reported as
migrated with no skip reason. This is exactly the silent-mis-migration failure mode the
commit set out to close.

**Evidence**

Lines 913-921:

```
if let expressionStatement = statement.item.as(ExpressionStmtSyntax.self) {
    expression = expressionStatement.expression
} else {
    expression = statement.item.as(ExprSyntax.self)
}
...
guard let expression else { continue }
```

`DoStmtSyntax` / `LabeledStmtSyntax` match neither branch. Failure input:

```
configurations: (0..<2).map { seed -> SnapshotConfiguration in
    do { return .init(name: "a", value: seed) }
    catch { return .init(name: "b", value: seed) }
}
```

→ `--apply` emits the bare `.init(...)`, records no skip, and the emitted code fails to
compile. The commit message asserts "the declaration is never emitted as silent
non-compiling code" — this shape violates that guarantee.

**Suggested fix**

In `collectConfigurationResultExpressions`, also descend into `DoStmtSyntax` (body plus
each `CatchClause` body) and unwrap `LabeledStmtSyntax` to its wrapped statement before
classifying. Alternatively, make `configurationsExpressionHasUnsupportedInitShorthand` a
true backstop by scanning the whole normalized-arguments syntax tree for any element-position
bare `.init` the rewriter did not edit, rather than reusing the same collector that has the
blind spot.

---

## Finding 2 — Non-implicit-member suite trait in first argument position is misclassified as a display name and silently dropped from the folded @Suite

- **Severity:** low
- **File:** `Sources/SnapshotMigrationSupport/Rewriting/SnapshotMigrationRewriter.swift:1557`
- **needs_dynamic_verification:** false

**Failure scenario**

The train-3 fix (`068a0a7`) rewrote `isDisplayNameArgument` to return true (treat as
display name, exclude from the trait fold) for any first argument that is NOT a leading-dot
implicit-member expression. This correctly stops non-literal display names (`Self.suiteName`,
`Constants.name`) being folded as traits. But `@SnapshotSuite` has a traits-only overload
`_ traits: any SnapshotSuiteTrait...` (`SnapshotSuiteMacroDefinition.swift:71`), so position
0 can legitimately be a trait. A trait written with an explicit base or a plain call —
`@SnapshotSuite(MyTraits.dark, .sizes(...))`, `@SnapshotSuite(CustomTrait())`,
`@SnapshotSuite(Module.SomeTrait.value)` — is not a leading-dot implicit member, so
`isImplicitMemberTraitExpression` returns false, `isDisplayNameArgument` returns true, and
the fold at line 1535 skips it. That first-position trait is silently omitted from the
surviving `@Suite`'s argument list (or, if it is the sole argument, `traitFoldingEdit`
returns nil and no traits fold at all). The migrated suite compiles but loses a trait (e.g.
a theme/size configuration), changing snapshot behavior, with no skip reason emitted. This
is the mirror-image regression of the bug the fix targeted. Scope is narrowed by the fold
path only firing when a legacy `@SnapshotSuite` and a hand-written argument-carrying
`@Suite` coexist on the same type.

**Evidence**

Line 1561 `return !isImplicitMemberTraitExpression(expression)`; lines 1567-1577 treat only
`MemberAccessExprSyntax` / `FunctionCallExprSyntax` with `memberAccess.base == nil` as a
trait. `CustomTrait()` is a `FunctionCall` whose callee is a `DeclReferenceExpr` (not a
member access) → false → classified as display name → line 1535
`if index == 0, isDisplayNameArgument(argument.expression) { continue }` drops it.
Traits-only overload confirmed at
`Sources/SnapshotTestingMacros/MacroDefinitions/SnapshotSuiteMacroDefinition.swift:71`.

**Suggested fix**

First-position ambiguity between `String?` display name and `any SnapshotSuiteTrait` cannot
be resolved syntactically for a non-literal, non-leading-dot expression. Rather than
guessing "display name", record an `unsupported`/ambiguous skip for a non-literal,
non-implicit-member first argument in the fold path so no trait is silently lost and no
non-literal display name is folded as a trait — preserving the safety-net discipline used
elsewhere in this file.
