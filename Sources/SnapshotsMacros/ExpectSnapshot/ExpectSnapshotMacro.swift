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
    /*
     The direct-value form — `#expectSnapshot(someView)` — is spliced into the `makeValue:`
     builder closure rather than passed positionally, even though the runtime surface could
     accept it as an `@autoclosure`.

     An autoclosure parameter fixes the effects of the expression it wraps at the point the
     overload is declared, and an autoclosure cannot be `async` at all. That is what forced the
     previous expansion to classify the value syntactically — a root-level `try` earned a
     `throwingMarker: ()` argument that routed the call to a throwing autoclosure overload — and
     it is why every other effect shape failed inside the expansion buffer, at a source location
     the author cannot open: `await` and `try await` with "'async' call in an autoclosure that
     does not support concurrency", and a `try` nested anywhere but the root (say,
     `Wrapper(inner: try make())`) with "Call can throw, but it is executed in a non-throwing
     autoclosure".

     A closure literal carries its own effects, so the compiler infers them from the spliced
     expression and picks the matching `makeValue:` overload itself — sync, `throws`, `async`, or
     `async throws` — with no marker argument and no syntactic classification here. `try?` and
     `try!` handle the error inside the expression, so they land on the non-throwing overload for
     free, which is what a reader would expect.

     Evaluation semantics are unchanged: the runtime's direct-value entry points already
     forwarded straight to the `makeValue:` builders, so the value was, and still is, produced
     lazily inside the main-actor hop — once per size/theme request — rather than at the call
     site.
     */
    let isDirectValue = argumentValue == nil && makeValueExpression == nil
    let directValue = isDirectValue ? value : nil
    let builderExpression =
      makeValueExpression.map { "\($0.trimmed)" }
      ?? directValue.map {
        """
        {
            \($0.trimmed)
          }
        """
      }
    let makeValue =
      builderExpression.map {
        """
        ,
          makeValue: \($0)
        """
      } ?? ""
    let valueArgument: String? =
      if directValue != nil {
        nil
      }
      else if let value, argumentValue == nil {
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
