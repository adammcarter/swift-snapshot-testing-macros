import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SnapshotSuiteMacro {}

extension SnapshotSuiteMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo _: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let macroContext = MacroContext(node: node, declaration: declaration, context: context)

    guard
      canContinueAfterSanityChecks(macroContext: macroContext)
    else { return [] }

    guard
      let snapshotSuite = SnapshotSuite(macroContext: macroContext)
    else { return [] }

    return [snapshotSuite.expression]
  }
}
