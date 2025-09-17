import SwiftSyntax
import SwiftSyntaxMacros

struct SnapshotSuite {
  /*
   ⚠️

   Important to include '.snapshots' trait to reset the counter for test repetitions. Without it
   the counter will continue to count up and create new reference images on each retry.
   */
  var expression: DeclSyntax {
    """
    @MainActor
    @Suite(\(suiteTraitsExpr))
    struct \(nameExpr) {
      \(commentExpr)
      \(contentsExpr)
    }
    """
  }

  private let macroContext: SnapshotSuiteMacroContext
  private let comment: String?
  private let testBlocks: [TestBlock]
  private let suiteTraitsExpr: FunctionCallExprSyntax

  private var nameExpr: TokenSyntax {
    let syntaxNodes = [
      macroContext.context.lexicalContext,
      [Syntax(macroContext.declaration)],
    ]
    .flatMap { $0 }

    let humanReadableUniqueName =
      syntaxNodes
      .compactMap(\.identifierName?.trimmedDescription)
      .joined(separator: "_")
      + Constants.GeneratedTypeName.generatedSnapshotSuite

    /*
     Avoid using the 'makeUniqueName()' function as it does create
     guaranteed unique names but also gives us names that are much
     more difficult to read at a glance.
     */

    /*
     The above solution of joining the lexical contexts by an '_'
     should be a good halfway point between almost guaranteed unique
     code for the trade off of easy to read suite names.
     */

    return .init(stringLiteral: humanReadableUniqueName)
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

  init?(comment: String? = nil, macroContext: SnapshotSuiteMacroContext) {
    self.comment = comment
    self.macroContext = macroContext

    let suiteMacroArguments = SnapshotsMacroArguments(node: macroContext.node)

    self.testBlocks = macroContext
      .declaration
      .memberBlock
      .members
      .map { member in
        .init(
          member: member,
          suiteMacroArguments: suiteMacroArguments,
          macroContext: macroContext
        )
      }

    let passedDiffTool = suiteMacroArguments
      .traitExpressions?
      .first {
        guard Constants.Trait(expression: $0) == .diffTool else {
          return false
        }

        return true
      }?
      .as(FunctionCallExprSyntax.self)?
      .arguments
      .first?
      .expression
      .trimmed

    let diffToolExpr =
      passedDiffTool
      ?? Constants.Trait.diffTool.asDefaultValueExpression
      ?? ""

    self.suiteTraitsExpr = FunctionCallExprSyntax(
      calledExpression: DeclReferenceExprSyntax(baseName: ".snapshots").trimmed,
      leftParen: .leftParenToken(),
      rightParen: .rightParenToken(),
      argumentsBuilder: {
        LabeledExprSyntax(
          label: "diffTool",
          colon: .colonToken(trailingTrivia: .space),
          expression: diffToolExpr
        )
      }
    )
  }
}

extension Constants.Trait {
  fileprivate var asDefaultValueExpression: ExprSyntax? {
    defaultInnerValue.flatMap {
      ExprSyntax(stringLiteral: $0)
    }
  }
}
