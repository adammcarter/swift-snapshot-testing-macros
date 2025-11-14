import SwiftSyntax

extension SnapshotSuite.TestBlock {
  struct IfConfig {
    var expression: IfConfigDeclSyntax { ifConfigDecl }

    private let ifConfigDecl: IfConfigDeclSyntax

    init(
      ifConfigDecl: IfConfigDeclSyntax,
      suiteMacroArguments: SnapshotMacroArguments,
      macroContext: SnapshotSuiteMacroContext
    ) {
      self.ifConfigDecl = ifConfigDecl.asIfConfigDeclTestExpr(
        suiteMacroArguments: suiteMacroArguments,
        macroContext: macroContext
      )
    }
  }
}

extension IfConfigDeclSyntax {
  fileprivate func asIfConfigDeclTestExpr(
    suiteMacroArguments: SnapshotMacroArguments,
    macroContext: SnapshotSuiteMacroContext
  ) -> IfConfigDeclSyntax {
    let clauses = clauses.compactMap { clause -> IfConfigClauseSyntax? in
      guard
        let memberBlockItemListExpr = clause.elements?.as(MemberBlockItemListSyntax.self)
      else {
        return nil
      }

      let blockItems = memberBlockItemListExpr.blockItemTestExprs(
        suiteMacroArguments: suiteMacroArguments,
        macroContext: macroContext
      )

      #warning("TODO: Replace this with an if block, if empty 'CodeBlockItemListSyntax { [comment] }' else existing, minus all the faff for trivia.")

      let trailingTrivia: Trivia =
        if blockItems.isEmpty {
          /*
         Add a line comment for the user but also so Xcode can format correctly.

         Without this Xcode treats the empty block as ignored and doesn't compile any #else blocks after

         It might be better to remove this block altogether but it makes it harder to read for the user as they mentally map their own code with the generated code if a block is missing.
         */
          .newlines(2).merging(.lineComment("// ⚠️ No tests could be generated for this block")).merging(.newline)
        }
        else { .none }

      var clause = clause
      clause.elements = .init(CodeBlockItemListSyntax { blockItems })
      clause.leadingTrivia = clause.leadingTrivia.newlinesOnly
      clause.trailingTrivia = trailingTrivia

      return clause
    }

    return with(\.clauses, IfConfigClauseListSyntax { clauses })
  }
}

extension MemberBlockItemListSyntax {
  fileprivate func blockItemTestExprs(
    suiteMacroArguments: SnapshotMacroArguments,
    macroContext: SnapshotSuiteMacroContext
  ) -> [CodeBlockItemSyntax] {
    compactMap {
      $0.decl.as(FunctionDeclSyntax.self)
    }
    .filter(\.isSupportedForSnapshots)
    .compactMap { snapshotTestFunctionDecl in
      let test = SnapshotSuite.TestBlock.Test(
        suiteMacroArguments: suiteMacroArguments,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl,
        macroContext: macroContext
      )

      var expression = test.expression
      expression.leadingTrivia = .newline

      return CodeBlockItemSyntax(item: .init(expression))
    }
  }
}
