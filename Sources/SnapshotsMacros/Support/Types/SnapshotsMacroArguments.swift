import SwiftSyntax

struct SnapshotsMacroArguments {
  let traitExpressions: [ExprSyntax]?
  let configurationsExpression: ExprSyntax?
  let configurationValuesExpression: ExprSyntax?

  init(node: AttributeSyntax) {
    traitExpressions = makeTraitExpressions(node: node)
    configurationsExpression = valueForParameterNamed("configurations", in: node)
    configurationValuesExpression = valueForParameterNamed("configurationValues", in: node)
  }

  init(
    traitExpressions: [ExprSyntax]?,
    configurationsExpression: ExprSyntax?,
    configurationValuesExpression: ExprSyntax?
  ) {
    self.traitExpressions = traitExpressions
    self.configurationsExpression = configurationsExpression
    self.configurationValuesExpression = configurationValuesExpression
  }
}

private func makeTraitExpressions(node: AttributeSyntax) -> [ExprSyntax]? {
  node
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .filter {
      $0.expression.is(StringLiteralExprSyntax.self) == false
        && $0.label == nil
    }
    .compactMap(\.expression)
}

private func valueForParameterNamed(_ name: String, in node: AttributeSyntax) -> ExprSyntax? {
  node
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .first { $0.label?.tokenKind == .identifier(name) }?
    .expression
}
