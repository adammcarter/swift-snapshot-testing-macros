import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ExpectSnapshotMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let unlabeledArguments = node.arguments.filter { $0.label == nil }
    let argumentValue = node.arguments.first { $0.label?.text == "argument" }?.expression

    guard let value = unlabeledArguments.first?.expression ?? argumentValue else {
      context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message: "#expectSnapshot requires an unlabeled value argument.",
          node: node
        )
      )

      return "()"
    }

    let named = node.arguments.first { $0.label?.text == "named" }?.expression ?? "nil"
    let makeValueClosure =
      node.trailingClosure
      ?? unlabeledArguments
      .dropFirst()
      .compactMap { $0.expression.as(ClosureExprSyntax.self) }
      .first
    let makeValue =
      makeValueClosure.map {
        """
        ,
          makeValue: \($0)
        """
      } ?? ""
    let valueArgument = if argumentValue == nil {
      "\(value)"
    } else {
      "argument: \(value)"
    }

    return ExprSyntax(
      stringLiteral: """
        SnapshotTestingMacros.__expectSnapshot(
          \(valueArgument),
          named: \(named),
          function: #function,
          fileID: #fileID,
          filePath: #filePath,
          line: #line,
          column: #column\(makeValue)
        )
        """
    )
  }
}
