import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GenerateTestMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    [
      """
      @Test
      func generatedByMacro() async throws {}
      """
    ]
  }
}

@main
struct tmp_intermacro_reproPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GenerateTestMacro.self,
  ]
}
