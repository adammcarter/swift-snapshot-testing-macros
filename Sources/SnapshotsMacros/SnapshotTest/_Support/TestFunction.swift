import SwiftSyntax

extension SnapshotSuite.TestBlock.Test {
  struct TestFunction {
    let nameExpr: IdentifierTypeSyntax
    let parametersExpr: FunctionParameterListSyntax?

    init(
      testName: TokenSyntax,
      configurationExpression: ExprSyntax?,
      snapshotTestFunctionDecl: FunctionDeclSyntax
    ) {
      nameExpr = IdentifierTypeSyntax(
        name: "\(raw: testName.generatedIdentifierComponent)_snapshotTest"
      )

      let configurationGenericType = snapshotTestFunctionDecl.signature.parameterClauseAsTuple

      parametersExpr =
        if configurationExpression != nil || configurationExpression?.as(ArrayExprSyntax.self)?.elements.isEmpty == false {
          FunctionParameterListSyntax {
            "\(.Parameters.configuration): \(.TypeName.snapshotConfiguration)<(\(configurationGenericType))>"
          }
        }
        else {
          nil
        }
    }
  }
}
