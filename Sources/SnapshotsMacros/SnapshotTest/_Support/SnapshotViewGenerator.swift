import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SnapshotTest {
  struct SnapshotViewGenerator {
    let displayNameExpr: ExprSyntax
    let makeValueExpr: ClosureExprSyntax
    let lineExpr: ExprSyntax
    let columnExpr: ExprSyntax

    init(
      suiteName: TokenSyntax,
      testName: String,
      displayName: String,
      declaration: Declaration,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      context: some MacroExpansionContext
    ) {
      displayNameExpr = .init(literal: displayName)

      makeValueExpr = makeMakeValue(
        suiteName: suiteName,
        testName: testName,
        declaration: declaration,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      let functionLocation = context.location(of: snapshotTestFunctionDecl)

      lineExpr = functionLocation?.line ?? "#line"
      columnExpr = functionLocation?.column ?? "#column"
    }
  }
}

/// Initialise the suite and call the function...
///
/// E.g.
///
/// ```
/// MySuite().makeView()
/// ```
private func makeMakeValue(
  suiteName: TokenSyntax,
  testName: String,
  declaration: Declaration,
  snapshotTestFunctionDecl: FunctionDeclSyntax
) -> ClosureExprSyntax {
  let isStatic = snapshotTestFunctionDecl.isStatic
  let isAsync = declaration.isAsync || snapshotTestFunctionDecl.isAsync
  let isThrows = declaration.isThrows || snapshotTestFunctionDecl.isThrows

  let arguments = snapshotTestFunctionDecl
    .signature
    .parameterClause
    .parameters
    .enumerated()
    .map { "\($1.name): $\($0)" }.map(ExprSyntax.init(stringLiteral:))
    .map { LabeledExprSyntax(expression: $0) }

  let baseFunction = FunctionCallExprSyntax(
    calledExpression: DeclReferenceExprSyntax(baseName: suiteName).trimmed,
    leftParen: isStatic ? .none : .leftParenToken(),
    rightParen: isStatic ? .none : .rightParenToken(),
    argumentsBuilder: {
      if let initConfigurationToken = declaration.initConfigurationToken {
        LabeledExprSyntax(
          label: initConfigurationToken,
          colon: .colonToken(trailingTrivia: .space),
          expression: ExprSyntax(stringLiteral: Constants.Parameters.configuration)
        )
      }
    }
  )

  var expression: ExprSyntaxProtocol = FunctionCallExprSyntax(
    calledExpression: MemberAccessExprSyntax(
      base: baseFunction,
      period: .periodToken(),
      declName: DeclReferenceExprSyntax(baseName: .identifier(testName))
    ),
    leftParen: .leftParenToken(),
    rightParen: .rightParenToken(),
    argumentsBuilder: { arguments }
  )

  if isAsync { expression = ExprSyntax(stringLiteral: "await \(expression)") }

  if isThrows { expression = ExprSyntax(stringLiteral: "try \(expression)") }

  // Wrap our function in a closure to avoid losing @MainActor annotation when otherwise passing directly.

  return ClosureExprSyntax(ExprSyntax("{ \(expression) }"))!
}
