import SwiftSyntax

extension SnapshotSuite {
  struct TestBlock {
    var expression: DeclSyntax? { ifConfig.flatMap { DeclSyntax($0.expression) } ?? test?.expression }

    private let ifConfig: IfConfig?
    private let test: Test?

    init(
      member: MemberBlockItemSyntax,
      suiteName: TokenSyntax,
      suiteDisplayName: String?,
      testDisplayName: String?,
      declaration: Declaration,
      suiteMacroArguments: SnapshotsMacroArguments,
      macroContext: MacroContext
    ) {
      var ifConfig: IfConfig?
      var test: Test?

      if let snapshotTestFunctionDecl = member.decl.as(FunctionDeclSyntax.self),
        snapshotTestFunctionDecl.isSupportedForSnapshots
      {
        test = .init(
          suiteName: suiteName,
          suiteDisplayName: suiteDisplayName,
          testDisplayName: testDisplayName,
          declaration: declaration,
          suiteMacroArguments: suiteMacroArguments,
          snapshotTestFunctionDecl: snapshotTestFunctionDecl,
          macroContext: macroContext
        )
      }
      else if let ifConfigDecl = member.decl.as(IfConfigDeclSyntax.self) {
        ifConfig = .init(
          ifConfigDecl: ifConfigDecl,
          member: member,
          suiteName: suiteName,
          suiteDisplayName: suiteDisplayName,
          testDisplayName: testDisplayName,
          declaration: declaration,
          suiteMacroArguments: suiteMacroArguments,
          macroContext: macroContext
        )
      }

      self.ifConfig = ifConfig
      self.test = test
    }
  }
}
