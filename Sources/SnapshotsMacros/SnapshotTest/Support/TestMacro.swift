import SwiftSyntax

extension SnapshotSuite.TestBlock.Test {
  struct TestMacro {
    var expr: LabeledExprListSyntax {
      LabeledExprListSyntax {
        for trait in swiftTestingTraits {
          LabeledExprSyntax(expression: trait)
        }

        if let argumentsExpression {
          LabeledExprSyntax(expression: ExprSyntax("arguments: \(argumentsExpression)"))
        }
      }
    }

    private let swiftTestingTraits: [ExprSyntax]
    private let configurationExpression: ExprSyntax?

    private var argumentsExpression: ExprSyntax? {
      configurationExpression.flatMap {
        let parserString = [
          Constants.Namespace.snapshotTestingMacros,
          Constants.TypeName.SnapshotConfigurationParser,
          "parse(\($0))",
        ]
        .joined(separator: ".")

        return ExprSyntax(stringLiteral: parserString)
      }
    }

    init(swiftTestingTraits: [ExprSyntax], configurationExpression: ExprSyntax?) {
      self.swiftTestingTraits = swiftTestingTraits
      self.configurationExpression = configurationExpression
    }
  }
}
