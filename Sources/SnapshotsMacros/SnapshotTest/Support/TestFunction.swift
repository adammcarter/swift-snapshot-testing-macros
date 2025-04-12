import SwiftSyntax

extension SnapshotSuite.TestBlock.Test {
  struct TestFunction {
    let nameExpr: IdentifierTypeSyntax
    let parametersExpr: FunctionParameterListSyntax?

    init(
      testName: String,
      configurationExpression: ExprSyntax?,
      snapshotTestFunctionDecl: FunctionDeclSyntax
    ) {
      nameExpr = IdentifierTypeSyntax(
        name: "assertSnapshot\(raw: testName.capitalizingFirst())"
      )

      let configurationGenericType = snapshotTestFunctionDecl.signature.parameterClauseAsTuple

      parametersExpr =
        if configurationExpression != nil || configurationExpression?.as(ArrayExprSyntax.self)?.elements.isEmpty == false {
          FunctionParameterListSyntax { "configuration: SnapshotConfiguration<(\(configurationGenericType))>" }
        }
        else {
          nil
        }
    }
  }
}
