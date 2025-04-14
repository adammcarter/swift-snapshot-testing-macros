import SwiftSyntax

struct SnapshotSuite {
  var expression: DeclSyntax {
    """
    @MainActor
    @Suite
    struct \(nameExpr) {
      \(commentExpr)
      \(contentsExpr)
    }
    """
  }

  private let macroContext: MacroContext
  private let comment: String?
  private let testBlocks: [TestBlock]

  private var nameExpr: ExprSyntax {
    .init(stringLiteral: Constants.GeneratedTypeName.generatedSnapshotSuite)
  }

  private var commentExpr: ExprSyntax? {
    comment.flatMap(ExprSyntax.init(stringLiteral:))
  }

  private var contentsExpr: MemberBlockItemListSyntax? {
    let testBlockExpressions = testBlocks.compactMap(\.expression)

    if testBlockExpressions.isEmpty {
      macroContext
        .context
        .diagnose(
          DiagnosticFactory.missingValidTests(
            node: macroContext.node,
            declaration: macroContext.declaration
          )
        )

      return nil
    }
    else {
      return MemberBlockItemListSyntax {
        testBlockExpressions
          .interspersing(leadingTrivia: .newlines(2))
      }
    }
  }

  init?(comment: String? = nil, macroContext: MacroContext) {
    self.comment = comment
    self.macroContext = macroContext

    guard let suiteName = (macroContext.declaration as? NamedDeclSyntax)?.name else { return nil }

    let suiteDisplayName = makeSuiteDisplayName(from: macroContext.node)
    let suiteMacroArguments = SnapshotsMacroArguments(node: macroContext.node)

    self.testBlocks = macroContext
      .declaration
      .memberBlock
      .members
      .map { member in
        .init(
          member: member,
          suiteName: suiteName,
          suiteDisplayName: suiteDisplayName,
          testDisplayName: makeTestDisplayName(from: member),
          declaration: Declaration(declaration: macroContext.declaration),
          suiteMacroArguments: suiteMacroArguments,
          macroContext: macroContext
        )
      }
  }
}

private func makeSuiteDisplayName(from attribute: AttributeSyntax) -> String? {
  makeDisplayName(from: attribute)
}

private func makeTestDisplayName(from member: MemberBlockItemSyntax) -> String? {
  let functionMember: MemberBlockItemSyntax?

  if let ifConfigDecl = member.decl.as(IfConfigDeclSyntax.self) {
    functionMember =
      ifConfigDecl
      .clauses
      .compactMap {
        $0.elements?.as(MemberBlockItemListSyntax.self)
      }
      .first?
      .first
  }
  else {
    functionMember = member
  }

  guard let functionMember else {
    return nil
  }

  let attribute = functionMember
    .decl
    .as(FunctionDeclSyntax.self)?
    .attributes
    .first {
      $0.hasAttributeNamed(Constants.AttributeName.snapshotTest)
    }?
    .as(AttributeSyntax.self)

  return makeDisplayName(from: attribute)
}

private func makeDisplayName(from attribute: AttributeSyntax?) -> String? {
  attribute?
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .first?
    .expression
    .as(StringLiteralExprSyntax.self)?
    .representedLiteralValue
}
