import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ExpectSnapshotMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard let value = node.arguments.first(where: { $0.label == nil })?.expression else {
      context.diagnose(
        DiagnosticFactory.generalMessage(
          message: "#expectSnapshot requires an unlabeled value argument.",
          node: node
        )
      )

      return "()"
    }

    let named = node.arguments.first { $0.label?.text == "named" }?.expression ?? "nil"

    return ExprSyntax(
      stringLiteral: """
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
    )
  }
}
