import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SnapshotSuite.TestBlock.Test {
  struct SnapshotGenerator {
    let displayNameExpr: ExprSyntax
    let traitsExpr: ArrayExprSyntax?
    let makeValueExpr: ClosureExprSyntax
    let lineExpr: ExprSyntax
    let columnExpr: ExprSyntax

    var configurationExpr: ExprSyntax? {
      ExprSyntax(stringLiteral: hasConfigurations ? "configuration" : ".none")
    }

    private let configurationsExpr: ExprSyntax?
    private let configurationValuesExpr: ExprSyntax?

    private var configurationArrayExpr: ArrayExprSyntax? {
      configurationsExpr?.as(ArrayExprSyntax.self)
    }

    private var hasConfigurations: Bool {
      configurationsExpr != nil || configurationValuesExpr != nil
    }

    init(
      suiteName: TokenSyntax,
      testName: String,
      displayName: String,
      declaration: Declaration,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      testMacroArguments: SnapshotsMacroArguments,
      traits: ArrayExprSyntax,
      macroContext: MacroContext
    ) {
      displayNameExpr = .init(literal: displayName)

      traitsExpr = traits

      configurationsExpr = testMacroArguments.configurationsExpression
      configurationValuesExpr = testMacroArguments.configurationValuesExpression

      makeValueExpr = makeMakeValue(
        suiteName: suiteName,
        testName: testName,
        declaration: declaration,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      let functionLocation = macroContext.context.location(of: snapshotTestFunctionDecl)

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
        LabeledExprSyntax(label: initConfigurationToken, colon: .colonToken(trailingTrivia: .space), expression: ExprSyntax(stringLiteral: "configuration"))
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
