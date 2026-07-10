# Audit round 2: macro-generics-surface

The 226c017 collapse of `#expectSnapshot` onto one generic core path (~25 run
overloads + 3 `runMainActorSnapshot` copies + 5 `runLazy` paths + 4 box types
-> 2 boxes, 4 effect cores, 1 canonical `@MainActor (CV) throws ->
SnapshotViewController` builder) is behaviourally sound. Verified by diffing
the pre-refactor adapter (`git 226c017^`) against HEAD and cross-checking the
12 `ExpectSnapshotErrorPolicyTests`: error policy per effect flavor is
preserved, the main-actor hop + failure-attribution bridge is essentially
identical, SwiftUI/SnapshotView->ViewController normalization is
byte-equivalent, execution-context binding / collision guard / `.N` counter
are called at the same points, and overload accounting is balanced 25:25:25:25
(macro declarations : `__expectSnapshot` runtime overloads : adapter shims :
call sites) with no missing or duplicated overload. No new correctness bug was
found in the collapse itself. One substantive finding is a residual of
round-1 finding #4 that the reader map had marked FIXED: a lone bare
function/closure reference as the sole `makeValue` argument is still
misclassified as the snapshot `value`, producing a confusing post-expansion
compile error with no macro diagnostic. Two improvement items round out the
report: a commit message/diff mismatch on the fix that landed part of finding
#4, and re-confirmation that round-1 low finding #8 (Optional stringification
in parser names, `SnapshotConfiguration.none` typing) remains open as
expected/deferred.

## Findings

### 1. Incomplete fix of round-1 finding #4: a lone bare function/closure reference as makeValue is still misclassified as the snapshot value
- **Severity:** low
- **File:** `Sources/SnapshotsMacros/ExpectSnapshot/ExpectSnapshotMacro.swift:17`
- **Failure scenario:** `#expectSnapshot(makeView)` where `func makeView() -> some View`, or `let build = { Text("x") }; #expectSnapshot(build)` — the macro emits `__expectSnapshot(makeView, named: nil, function:, ...)` with no `makeValue:` argument, which matches no runtime overload, producing a confusing post-expansion "no exact matches in call to global function `__expectSnapshot`" error with no macro-level diagnostic pointing at the real problem.
- **Evidence:** `ExpectSnapshotMacro.swift:17-18` treats the first unlabeled argument as `value` whenever it is not a `ClosureExprSyntax` literal; `:26-31` then computes `makeValueArguments = unlabeledArguments.dropFirst()`, leaving nothing; `:38-40` leaves `makeValueExpression` nil when there's no trailing closure and no remaining args. The fix commit `65a0795` (`git show 65a0795 -- .../ExpectSnapshotMacro.swift`) only renamed `makeValueClosure`->`makeValueExpression` for the SECOND+ argument case, never touching first-arg classification. Macro tests cover only `expandsFunctionReferenceMakeValueAfterConfiguration` (line 488) and `expandsFunctionReferenceMakeValueAfterArgument` (line 530); `rg 'expectSnapshot\((makeView|build|makeHeader)\)' Tests/` returns nothing. The macro comment at `:32-37` claims sole function references are captured, overstating actual coverage. Round-1 report `docs/audit/macro-generics-surface.md:36` listed exactly this case (`#expectSnapshot(makeHeader)`, `#expectSnapshot(build)`) as broken.
- **Suggested fix:** Either (a) diagnose explicitly when the sole unlabeled argument cannot be a View literal and no makeValue/trailing closure is present, or (b) document the limitation and correct the misleading comment. Add a compile-fail/`assertMacro` fixture for `#expectSnapshot(makeView)` to lock the chosen behaviour.
- **needs_dynamic_verification:** true (the misclassification logic is statically certain; the resulting end-to-end compile error was not independently re-triggered by building)

### 2. History hygiene: the macro trivia/classification fix is buried in a commit whose message describes unrelated CI work
- **Severity:** improvement
- **File:** `Sources/SnapshotsMacros/ExpectSnapshot/ExpectSnapshotMacro.swift:1`
- **Failure scenario:** N/A — traceability issue, not a code defect. Anyone bisecting the macro's trivia/classification behaviour via `git log` will not find this commit by its message.
- **Evidence:** `git show 65a0795 --stat` and the diff show the commit message reads "ci: trigger reference recording from record/** branches" (body discusses `workflow_dispatch` triggers only) while the actual diff is the `ExpectSnapshotMacro.swift` behavioural fix (`makeValueClosure`->`makeValueExpression`, plus `.trimmed` interpolation for round-1 finding #3).
- **Suggested fix:** If the branch is still being rebased before merge, split or reword `65a0795` so the macro fix carries an accurate message (e.g. "fix: capture non-literal makeValue and trim argument trivia in #expectSnapshot expansion").
- **needs_dynamic_verification:** false

### 3. Confirmed still-open round-1 low findings (#8): Optional stringification in parser names and SnapshotConfiguration.none typing
- **Severity:** improvement
- **File:** `Sources/SnapshotTestingMacros/SnapshotConfiguration/SnapshotConfigurationParser.swift:28`
- **Failure scenario:** (1) `SnapshotConfigurationParser.parse([T])` names each element `"\($0)"`; for `T == Optional<String>` a `.some("x")` element is named `Optional("x")` -> normalized `Optional-x`, inconsistent with the documented explicit-name-for-optionals convention. (2) `SnapshotConfiguration.none` is declared `public static var none: SnapshotConfiguration<Void>` on the generic `SnapshotConfiguration<T>` (`SnapshotConfiguration.swift:66`), so `SnapshotConfiguration<Int>.none` still resolves and silently returns a Void-typed configuration instead of failing to compile.
- **Evidence:** `SnapshotConfigurationParser.swift:26-29`; `SnapshotConfiguration.swift:66-68`. Matches round-1 `docs/audit/macro-generics-surface.md` finding #8; the reader map notes both as intentionally left unfixed (low priority, not regressions).
- **Suggested fix:** If touched later: unwrap Optionals for naming in `parse([T])` (nil -> "nil", some -> describe wrapped value), and constrain `none` to an extension `where T == Void`. Otherwise leave as documented low-priority warts.
- **needs_dynamic_verification:** false
