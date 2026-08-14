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
    let trailingClosure = node.trailingClosure
    let value: ExprSyntax? =
      if let argumentValue {
        argumentValue
      }
      else if let firstUnlabeledArgument = unlabeledArguments.first,
        firstUnlabeledArgument.expression.as(ClosureExprSyntax.self) == nil
      {
        firstUnlabeledArgument.expression
      }
      else {
        nil
      }
    let makeValueArguments =
      if argumentValue == nil, value != nil {
        unlabeledArguments.dropFirst()
      }
      else {
        unlabeledArguments[...]
      }
    /*
     Every remaining unlabeled argument is the value builder regardless of its syntax kind:
     the macro declarations accept any expression of function type (a closure literal, a
     function reference like `makeHeader`, or a stored closure), so classifying on
     `ClosureExprSyntax` alone would silently drop non-literal builders from the expansion.
     */
    let makeValueExpression: ExprSyntax? =
      trailingClosure.map { ExprSyntax($0) }
      ?? makeValueArguments.first?.expression

    guard value != nil || makeValueExpression != nil else {
      context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message: "#expectSnapshot requires an unlabeled value argument or closure.",
          node: node
        )
      )

      return "()"
    }

    /*
     Interpolated nodes are `.trimmed` before splicing: `SyntaxProtocol.description` includes
     trailing trivia, and a same-line `// comment` after an argument (comment without a
     newline, so it rides on the expression's last token) would otherwise be spliced directly
     before the template's `,`, commenting out the rest of the generated line.
     */
    let named = node.arguments.first { $0.label?.text == "named" }?.expression.trimmed ?? "nil"
    let makeValue =
      makeValueExpression.map {
        """
        ,
          makeValue: \($0.trimmed)
        """
      } ?? ""
    let valueArgument: String? =
      if let value, argumentValue == nil {
        "\(value.trimmed)"
      }
      else if let value {
        "argument: \(value.trimmed)"
      }
      else {
        nil
      }
    let leadingArguments = valueArgument.map { "  \($0),\n" } ?? ""
    let expansion =
      "SnapshotTestingMacros.__expectSnapshot(\n"
      + leadingArguments
        + """
          named: \(named),
          function: #function,
          fileID: #fileID,
          filePath: #filePath,
          line: #line,
          column: #column\(makeValue)
        )
        """

    return ExprSyntax(
      stringLiteral: expansion
    )
  }
}
