import SwiftSyntax
import SwiftSyntaxMacros

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

  private let macroContext: SnapshotSuiteMacroContext
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
  }
}
