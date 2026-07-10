import SwiftSyntax

/// The plain string-literal display name carried by a `@SnapshotSuite`/`@SnapshotTest`
/// attribute.
///
/// Mirrors the legacy semantics exactly: only a leading, non-interpolated string literal
/// counts (`representedLiteralValue` is `nil` for interpolations, which fall through to the
/// next name in the fallback chain).
func makeDisplayName(from attribute: AttributeSyntax?) -> String? {
  attribute?
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .first?
    .expression
    .as(StringLiteralExprSyntax.self)?
    .representedLiteralValue
}
