import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SnapshotTest {
  struct SnapshotGenerator {
    let displayNameExpr: ExprSyntax
    let traitsExpr: ArrayExprSyntax?
    let makeValueExpr: ClosureExprSyntax
    let lineExpr: ExprSyntax
    let columnExpr: ExprSyntax

    init(
      suiteName: TokenSyntax,
      testName: String,
      displayName: String,
      declaration: Declaration,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      traits: ArrayExprSyntax,
      context: some MacroExpansionContext
    ) {
      displayNameExpr = .init(literal: displayName)

      let suiteTrait = context.lexicalContext
        .compactMap {
          if let snapshotSuiteAttribute = $0.attributesList?.first(attributeNamed: Constants.AttributeName.snapshotSuite)?.as(AttributeSyntax.self) {
            snapshotSuiteAttribute.arguments?.as(LabeledExprListSyntax.self)
          }
          else {
            nil
          }
        }
        .first

      traitsExpr = makeTraitsArrayExpr(
        suiteTraitExpressions: suiteTrait?.map(\.expression),
        testTraitExpressions: traits.elements.map(\.expression),
        context: context,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl,
        addDefaults: true
      )

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
          expression: ExprSyntax(stringLiteral: "configuration")
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
