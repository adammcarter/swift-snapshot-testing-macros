import SwiftSyntax
import SwiftSyntaxMacros

struct SnapshotSuite {
  var expressions: [DeclSyntax] {
    contentsExpr?.map(\.decl) ?? []
  }

  private let macroContext: SnapshotSuiteMacroContext
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
    guard let hostTypeName = Syntax(macroContext.declaration).identifierName?.trimmed else {
      return nil
    }

    self.macroContext = macroContext

    let suiteMacroArguments = SnapshotMacroArguments(node: macroContext.node)
    let inheritedTestTraitExprs = makeInheritedTestTraitExprs(from: suiteMacroArguments.traitExpressions)

    self.testBlocks = macroContext
      .declaration
      .memberBlock
      .members
      .map { member in
        .init(
          member: member,
          hostTypeName: hostTypeName,
          inheritedTestTraitExprs: inheritedTestTraitExprs,
          suiteMacroArguments: suiteMacroArguments,
          macroContext: macroContext
        )
      }
  }

  private let testBlocks: [TestBlock]
}

private func makeInheritedTestTraitExprs(
  from traitExprs: [ExprSyntax]?
) -> [ExprSyntax] {
  let snapshotsTrait = ".pointfreeSnapshots" as ExprSyntax
  let boxedTraits =
    traitExprs?
    .map {
      "\(raw: Constants.Namespace.snapshotTestingMacros).__TestTraitBox(\($0.trimmed)).wrapped" as ExprSyntax
    } ?? []

  return [snapshotsTrait] + boxedTraits
}
