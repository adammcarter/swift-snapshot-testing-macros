import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SnapshotTestMacro {}

/// This Macro definitions has no implementation and is used solely as an anchor to help setup a `@SnapshotSuite`.
extension SnapshotTestMacro: PeerMacro {
  public static func expansion(
    of _: AttributeSyntax,
    providingPeersOf _: some DeclSyntaxProtocol,
    in _: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
