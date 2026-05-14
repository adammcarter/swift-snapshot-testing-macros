import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ExpectSnapshotMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in _: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let value = node.arguments.first { $0.label == nil }!.expression
    let named = node.arguments.first { $0.label?.text == "named" }?.expression ?? "nil"

    return """
    SnapshotTestingMacros.__expectSnapshot(
      \(value),
      named: \(named),
      function: #function,
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )
    """
  }
}
