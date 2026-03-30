import SwiftSyntax

extension SnapshotSuite {
  struct TestBlock {
    var expression: DeclSyntax? {
      ifConfig.flatMap { DeclSyntax($0.expression) }
        ?? test?.expression
    }

    private let ifConfig: IfConfig?
    private let test: Test?

    init(
      member: MemberBlockItemSyntax,
      hostTypeName: TokenSyntax,
      inheritedTestTraitExprs: [ExprSyntax],
      suiteMacroArguments: SnapshotMacroArguments,
      macroContext: SnapshotSuiteMacroContext
    ) {
      var ifConfig: IfConfig?
      var test: Test?

      if let snapshotTestFunctionDecl = member.decl.as(FunctionDeclSyntax.self),
        snapshotTestFunctionDecl.isSupportedForSnapshots
      {
        test = .init(
          hostTypeName: hostTypeName,
          inheritedTestTraitExprs: inheritedTestTraitExprs,
          suiteMacroArguments: suiteMacroArguments,
          snapshotTestFunctionDecl: snapshotTestFunctionDecl,
          macroContext: macroContext
        )
      }
      else if let ifConfigDecl = member.decl.as(IfConfigDeclSyntax.self) {
        ifConfig = .init(
          ifConfigDecl: ifConfigDecl,
          hostTypeName: hostTypeName,
          inheritedTestTraitExprs: inheritedTestTraitExprs,
          suiteMacroArguments: suiteMacroArguments,
          macroContext: macroContext
        )
      }

      self.ifConfig = ifConfig
      self.test = test
    }
  }
}
