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
      nameExpr = IdentifierTypeSyntax(name: "assertSnapshot\(raw: testName.capitalizingFirst())")

      let configurationGenericType = makeConfigurationGenericType(
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

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

private func makeConfigurationGenericType(
  snapshotTestFunctionDecl: FunctionDeclSyntax
) -> TupleTypeElementListSyntax {
  .init {
    snapshotTestFunctionDecl
      .signature
      .parameterClause
      .parameters
      .map { .init(type: $0.type) }
  }
}
