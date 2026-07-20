import SwiftSyntax

struct SnapshotMacroArguments {
  let traitExpressions: [ExprSyntax]?
  let configurationsExpression: ExprSyntax?
  let configurationValuesExpression: ExprSyntax?

  init(node: AttributeSyntax?) {
    traitExpressions = makeTraitExpressions(node: node)
    configurationsExpression = valueForParameterNamed(Constants.Parameters.configurations, in: node)
    configurationValuesExpression = valueForParameterNamed(Constants.Parameters.configurationValues, in: node)
  }
}

private func makeTraitExpressions(node: AttributeSyntax?) -> [ExprSyntax]? {
  node?
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .filter {
      // String and nil literals can only ever be the optional display name — never a trait.
      // Boxing a `nil` display name as a trait generates non-compiling code.
      $0.expression.is(StringLiteralExprSyntax.self) == false
        && $0.expression.is(NilLiteralExprSyntax.self) == false
        && $0.label == nil
    }
    .compactMap(\.expression)
}

private func valueForParameterNamed(_ name: String, in node: AttributeSyntax?) -> ExprSyntax? {
  node?
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .first { $0.label?.tokenKind == .identifier(name) }?
    .expression
}
