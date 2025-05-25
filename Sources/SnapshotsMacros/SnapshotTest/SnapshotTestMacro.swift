import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SnapshotTestMacro {}

/// This Macro definitions has no implementation and is used solely as an anchor to help setup a `@SnapshotSuite`.
extension SnapshotTestMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let macroContext = SnapshotTestMacroContext(
      node: node,
      declaration: declaration,
      context: context
    )

    guard
      let snapshotTest = SnapshotTest(macroContext: macroContext)
    else {
      return []
    }

    return [snapshotTest.expression]
  }
}

typealias SnapshotTestMacroContext = MacroContext<DeclSyntaxProtocol>
