import Foundation
import SwiftParser
import SwiftSyntax

public struct RewriteReason: Equatable, Codable {
  public let code: String
  public let message: String
  public let line: Int
  public let column: Int

  public init(code: String, message: String, line: Int, column: Int) {
    self.code = code
    self.message = message
    self.line = line
    self.column = column
  }
}

public struct RewriteResult: Equatable {
  public let output: String
  public let reasons: [RewriteReason]
  public let changed: Bool

  public init(output: String, reasons: [RewriteReason], changed: Bool) {
    self.output = output
    self.reasons = reasons
    self.changed = changed
  }
}

public struct SnapshotMigrationRewriter {
  public init() {}

  public func rewrite(source: String) throws -> RewriteResult {
    let tree = Parser.parse(source: source)
    var collector = RewriteCollector(viewMode: .sourceAccurate)
    collector.walk(tree)

    let converter = SourceLocationConverter(fileName: "", tree: tree)
    var reasons: [RewriteReason] = []
    var edits: [TextEdit] = collector.attributeEdits

    for legacyFunction in collector.legacyFunctions {
      guard let body = legacyFunction.function.body,
            let expression = extractBodyExpression(from: legacyFunction.function)
      else {
        let location = converter.location(for: legacyFunction.function.positionAfterSkippingLeadingTrivia)
        reasons.append(
          RewriteReason(
            code: "unsupported-signature-shape",
            message: "Legacy declaration found but no safe rewrite pattern matched.",
            line: location.line,
            column: location.column
          )
        )
        continue
      }

      if let returnClause = legacyFunction.function.signature.returnClause,
         returnClause.type.trimmedDescription == "some View"
      {
        edits.append(
          TextEdit(
            startUTF8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
            endUTF8Offset: returnClause.endPositionBeforeTrailingTrivia.utf8Offset,
            replacement: ""
          )
        )
      }

      edits.append(
        TextEdit(
          startUTF8Offset: body.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: body.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: rewriteBody(
            expression: expression,
            namedLiteral: legacyFunction.namedLiteral,
            body: body,
            source: source
          )
        )
      )
    }

    let output = apply(edits: edits, to: source)
    return RewriteResult(output: output, reasons: reasons, changed: output != source)
  }

  private func extractBodyExpression(from function: FunctionDeclSyntax) -> String? {
    guard function.signature.parameterClause.parameters.isEmpty else { return nil }
    guard let body = function.body else { return nil }

    let statements = body.statements
    guard statements.count == 1, let statement = statements.first else { return nil }

    if let returnStatement = statement.item.as(ReturnStmtSyntax.self),
       let expression = returnStatement.expression
    {
      return expression.trimmedDescription
    }

    if let expressionStatement = statement.item.as(ExpressionStmtSyntax.self) {
      return expressionStatement.expression.trimmedDescription
    }

    return nil
  }

  private func rewriteBody(
    expression: String,
    namedLiteral: String?,
    body: CodeBlockSyntax,
    source: String
  ) -> String {
    let closingIndent = indentation(atUTF8Offset: body.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset, in: source)
    let statementIndent = body
      .statements
      .first
      .map { indentation(atUTF8Offset: $0.positionAfterSkippingLeadingTrivia.utf8Offset, in: source) }
      ?? (closingIndent + "  ")

    let namedSuffix = namedLiteral.map { ", named: \($0)" } ?? ""

    return """
    {
    \(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue\(namedSuffix))
    \(closingIndent)}
    """
  }

  private func indentation(atUTF8Offset utf8Offset: Int, in source: String) -> String {
    let position = index(atUTF8Offset: utf8Offset, in: source)
    let lineStart = source[..<position].lastIndex(of: "\n").map { source.index(after: $0) } ?? source.startIndex
    let prefix = source[lineStart..<position]
    let indentation = prefix.prefix { $0 == " " || $0 == "\t" }
    return String(indentation)
  }

  private func apply(edits: [TextEdit], to source: String) -> String {
    var output = source

    let uniqueEdits = Array(Set(edits)).sorted { lhs, rhs in
      if lhs.startUTF8Offset == rhs.startUTF8Offset {
        return lhs.endUTF8Offset > rhs.endUTF8Offset
      }
      return lhs.startUTF8Offset > rhs.startUTF8Offset
    }

    for edit in uniqueEdits {
      let start = index(atUTF8Offset: edit.startUTF8Offset, in: output)
      let end = index(atUTF8Offset: edit.endUTF8Offset, in: output)
      output.replaceSubrange(start..<end, with: edit.replacement)
    }

    return output
  }

  private func index(atUTF8Offset utf8Offset: Int, in source: String) -> String.Index {
    let clampedOffset = max(0, min(utf8Offset, source.utf8.count))
    let utf8Index = source.utf8.index(source.utf8.startIndex, offsetBy: clampedOffset)
    return String.Index(utf8Index, within: source) ?? source.endIndex
  }
}

private struct RewriteCollector {
  private(set) var attributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []

  init(viewMode: SyntaxTreeViewMode) {
    self.visitor = RewriteCollectorVisitor(viewMode: viewMode)
  }

  private var visitor: RewriteCollectorVisitor

  mutating func walk(_ tree: SourceFileSyntax) {
    visitor.walk(tree)
    attributeEdits = visitor.attributeEdits
    legacyFunctions = visitor.legacyFunctions
  }
}

private final class RewriteCollectorVisitor: SyntaxVisitor {
  private(set) var attributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []

  override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
      return .visitChildren
    }

    if identifier == "SnapshotSuite" {
      attributeEdits.append(
        TextEdit(
          startUTF8Offset: node.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: node.attributeName.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: "Suite"
        )
      )
    } else if identifier == "SnapshotTest" {
      attributeEdits.append(
        TextEdit(
          startUTF8Offset: node.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: node.attributeName.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: "Test"
        )
      )
    }

    return .visitChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let snapshotAttribute = snapshotTestAttribute(in: node.attributes) else {
      return .visitChildren
    }

    let namedLiteral = namedLiteral(from: snapshotAttribute)
    let legacyFunction = LegacyFunction(function: node, namedLiteral: namedLiteral)
    legacyFunctions.append(legacyFunction)

    return .visitChildren
  }

  private func snapshotTestAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
    attributes
      .compactMap { $0.as(AttributeSyntax.self) }
      .first { attribute in
        attribute.attributeName
          .as(IdentifierTypeSyntax.self)?
          .name
          .trimmed
          .text == "SnapshotTest"
      }
  }

  private func namedLiteral(from attribute: AttributeSyntax) -> String? {
    guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else { return nil }
    guard arguments.count == 1, let first = arguments.first else { return nil }
    guard first.label == nil else { return nil }
    return first.expression.as(StringLiteralExprSyntax.self)?.trimmedDescription
  }
}

private struct LegacyFunction: Hashable {
  let function: FunctionDeclSyntax
  let namedLiteral: String?
}

private struct TextEdit: Hashable {
  let startUTF8Offset: Int
  let endUTF8Offset: Int
  let replacement: String
}
