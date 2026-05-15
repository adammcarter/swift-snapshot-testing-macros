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
    let firstUnlabeledClosure =
      unlabeledArguments
      .compactMap { $0.expression.as(ClosureExprSyntax.self) }
      .first
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
    let makeValueClosure =
      trailingClosure
      ?? firstUnlabeledClosure
      ?? makeValueArguments
      .compactMap { $0.expression.as(ClosureExprSyntax.self) }
      .first

    guard value != nil || makeValueClosure != nil else {
      context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message: "#expectSnapshot requires an unlabeled value argument or closure.",
          node: node
        )
      )

      return "()"
    }

    let named = node.arguments.first { $0.label?.text == "named" }?.expression ?? "nil"
    let makeValue =
      makeValueClosure.map {
        """
        ,
          makeValue: \($0)
        """
      } ?? ""
    let valueArgument: String? =
      if let value, argumentValue == nil {
        "\(value)"
      }
      else if let value {
        "argument: \(value)"
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
