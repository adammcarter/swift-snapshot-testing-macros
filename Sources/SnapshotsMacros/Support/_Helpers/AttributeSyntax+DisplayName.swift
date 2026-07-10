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

/// A leading display-name argument the macro cannot evaluate statically — a string literal
/// containing interpolation. Left undiagnosed it silently falls back to the function or type
/// name, so callers should reject it with an error instead.
func unrepresentableDisplayNameArgument(in attribute: AttributeSyntax?) -> StringLiteralExprSyntax? {
  guard
    let firstArgument = attribute?.arguments?.as(LabeledExprListSyntax.self)?.first,
    firstArgument.label == nil,
    let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
    stringLiteral.representedLiteralValue == nil
  else {
    return nil
  }

  return stringLiteral
}
