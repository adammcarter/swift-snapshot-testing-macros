import SwiftSyntax

extension SnapshotSuite.TestBlock.Test {
  struct TestMacro {
    var expr: LabeledExprListSyntax {
      LabeledExprListSyntax {
        for trait in traits {
          LabeledExprSyntax(expression: trait)
        }

        if let argumentsExpression {
          LabeledExprSyntax(expression: ExprSyntax("arguments: \(argumentsExpression)"))
        }
      }
    }

    private let traits: [ExprSyntax]
    private let configurationExpression: ExprSyntax?
    private let configurationValuesExpression: ExprSyntax?
    private let configurationNameTransformExpression: ExprSyntax?

    private var argumentsExpression: ExprSyntax? {
      configurationExpression.flatMap {
        let parseExpression: String
        if configurationValuesExpression != nil, let configurationNameTransformExpression {
          parseExpression = "parse(\($0), configurationNameTransform: \(configurationNameTransformExpression))"
        }
        else {
          parseExpression = "parse(\($0))"
        }

        let parserString = [
          Constants.Namespace.snapshotTestingMacros,
          Constants.TypeName.snapshotConfigurationParser,
          parseExpression,
        ]
        .joined(separator: ".")

        return ExprSyntax(stringLiteral: parserString)
      }
    }

    init(
      traits: [ExprSyntax],
      configurationExpression: ExprSyntax?,
      configurationValuesExpression: ExprSyntax?,
      configurationNameTransformExpression: ExprSyntax?
    ) {
      self.traits = traits
      self.configurationExpression = configurationExpression
      self.configurationValuesExpression = configurationValuesExpression
      self.configurationNameTransformExpression = configurationNameTransformExpression
    }
  }
}
