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
    var edits: [TextEdit] = collector.suiteAttributeEdits

    for legacyFunction in collector.legacyFunctions {
      if let parseIssue = legacyFunction.parseIssue {
        reasons.append(
          makeReason(
            code: parseIssue.code,
            message: parseIssue.message,
            utf8Offset: legacyFunction.snapshotAttributeNameStartUTF8Offset,
            converter: converter,
            source: source
          )
        )
        continue
      }

      let functionEdits: [TextEdit]?
      if let parameterizedArgument = legacyFunction.parameterizedArgument {
        functionEdits = rewriteParameterizedFunction(
          legacyFunction: legacyFunction,
          parameterizedArgument: parameterizedArgument,
          source: source,
          converter: converter,
          reasons: &reasons
        )
      } else {
        functionEdits = rewriteNonParameterizedFunction(
          legacyFunction: legacyFunction,
          source: source,
          converter: converter,
          reasons: &reasons
        )
      }

      if let functionEdits {
        edits.append(contentsOf: functionEdits)
      }
    }

    let output = apply(edits: edits, to: source)
    return RewriteResult(output: output, reasons: reasons, changed: output != source)
  }

  private func rewriteNonParameterizedFunction(
    legacyFunction: LegacyFunction,
    source: String,
    converter: SourceLocationConverter,
    reasons: inout [RewriteReason]
  ) -> [TextEdit]? {
    let function = legacyFunction.function
    guard function.signature.parameterClause.parameters.isEmpty else {
      reasons.append(
        makeReason(
          code: "unsupported-signature-shape",
          message: "Non-parameterized @SnapshotTest requires a zero-parameter function.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    guard let body = function.body,
          let expression = extractBodyExpression(from: function)
    else {
      reasons.append(
        makeReason(
          code: "unsupported-signature-shape",
          message: "Legacy declaration found but no safe rewrite pattern matched.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    var functionEdits: [TextEdit] = [
      TextEdit(
        startUTF8Offset: legacyFunction.snapshotAttributeNameStartUTF8Offset,
        endUTF8Offset: legacyFunction.snapshotAttributeNameEndUTF8Offset,
        replacement: "Test"
      )
    ]

    if let returnClause = function.signature.returnClause {
      guard PlatformClassifier.classify(returnType: returnClause.type.trimmedDescription) != .unsupported else {
        reasons.append(
          makeReason(
            code: "unsupported-platform-form",
            message: "Legacy return type is not supported for automatic migration.",
            utf8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
            converter: converter,
            source: source
          )
        )
        return nil
      }

      functionEdits.append(
        TextEdit(
          startUTF8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: returnClause.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: ""
        )
      )
    }

    functionEdits.append(
      TextEdit(
        startUTF8Offset: body.positionAfterSkippingLeadingTrivia.utf8Offset,
        endUTF8Offset: body.endPositionBeforeTrailingTrivia.utf8Offset,
        replacement: rewriteDirectBody(
          expression: expression,
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      )
    )

    return functionEdits
  }

  private func rewriteParameterizedFunction(
    legacyFunction: LegacyFunction,
    parameterizedArgument: ParameterizedSnapshotArgument,
    source: String,
    converter: SourceLocationConverter,
    reasons: inout [RewriteReason]
  ) -> [TextEdit]? {
    let function = legacyFunction.function

    guard let returnClause = function.signature.returnClause else {
      reasons.append(
        makeReason(
          code: "unsupported-platform-form",
          message: "Parameterized migration requires a recognized legacy snapshot return type.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    let platform = PlatformClassifier.classify(returnType: returnClause.type.trimmedDescription)
    guard platform != .unsupported else {
      reasons.append(
        makeReason(
          code: "unsupported-platform-form",
          message: "Legacy return type is not supported for automatic parameterized migration.",
          utf8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    guard let body = function.body,
          let expression = extractBodyExpression(from: function)
    else {
      reasons.append(
        makeReason(
          code: "unsupported-signature-shape",
          message: "Legacy declaration found but no safe rewrite pattern matched.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    guard let normalizedArguments = normalizeArgumentsExpression(parameterizedArgument.expressionText) else {
      reasons.append(
        makeReason(
          code: "unsupported-attribute-arguments",
          message: "Could not normalize attribute arguments to a safe @Test(arguments:) form.",
          utf8Offset: parameterizedArgument.expressionStartUTF8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    guard let parameterInfos = functionParameterInfos(from: function) else {
      reasons.append(
        makeReason(
          code: "unsupported-signature-shape",
          message: "Function parameters are not in a migratable shape.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    if platform == .uiKitOrAppKit,
       requiresUnsupportedArgumentNamingSkip(
         kind: parameterizedArgument.kind,
         normalizedArguments: normalizedArguments,
         legacyNameLiteral: legacyFunction.namedLiteral
       )
    {
      reasons.append(
        makeReason(
          code: "unsupported-argument-naming",
          message: "Could not derive deterministic unique names for parameterized UIKit/AppKit artifacts.",
          utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
          converter: converter,
          source: source
        )
      )
      return nil
    }

    var functionEdits: [TextEdit] = [
      TextEdit(
        startUTF8Offset: legacyFunction.snapshotAttributeNameStartUTF8Offset,
        endUTF8Offset: legacyFunction.snapshotAttributeNameEndUTF8Offset,
        replacement: "Test"
      ),
      TextEdit(
        startUTF8Offset: parameterizedArgument.labelStartUTF8Offset,
        endUTF8Offset: parameterizedArgument.labelEndUTF8Offset,
        replacement: "arguments"
      ),
      TextEdit(
        startUTF8Offset: parameterizedArgument.expressionStartUTF8Offset,
        endUTF8Offset: parameterizedArgument.expressionEndUTF8Offset,
        replacement: normalizedArguments
      ),
      TextEdit(
        startUTF8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
        endUTF8Offset: returnClause.endPositionBeforeTrailingTrivia.utf8Offset,
        replacement: ""
      ),
    ]

    let rewrittenBody: String
    switch parameterizedArgument.kind {
    case .configurations:
      guard !parameterInfos.isEmpty else {
        reasons.append(
          makeReason(
            code: "unsupported-signature-shape",
            message: "`configurations:` migration requires at least one function parameter.",
            utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
            converter: converter,
            source: source
          )
        )
        return nil
      }

      let configurationType = snapshotConfigurationValueType(for: parameterInfos)
      let replacementParameters = "(configuration: SnapshotConfiguration<\(configurationType)>)"
      functionEdits.append(
        TextEdit(
          startUTF8Offset: function.signature.parameterClause.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: function.signature.parameterClause.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: replacementParameters
        )
      )

      switch platform {
      case .swiftUI:
        rewrittenBody = rewriteSwiftUIConfigurationsBody(
          expression: expression,
          parameterNames: parameterInfos.map(\.localName),
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationsBody(
          expression: expression,
          parameterNames: parameterInfos.map(\.localName),
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      case .unsupported:
        return nil
      }
    case .configurationValues:
      guard parameterInfos.count == 1 else {
        reasons.append(
          makeReason(
            code: "unsupported-signature-shape",
            message: "`configurationValues:` migration requires exactly one function parameter.",
            utf8Offset: function.positionAfterSkippingLeadingTrivia.utf8Offset,
            converter: converter,
            source: source
          )
        )
        return nil
      }

      let parameterName = parameterInfos[0].localName
      switch platform {
      case .swiftUI:
        rewrittenBody = rewriteSwiftUIConfigurationValuesBody(
          expression: expression,
          parameterName: parameterName,
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationValuesBody(
          expression: expression,
          parameterName: parameterName,
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      case .unsupported:
        return nil
      }
    }

    functionEdits.append(
      TextEdit(
        startUTF8Offset: body.positionAfterSkippingLeadingTrivia.utf8Offset,
        endUTF8Offset: body.endPositionBeforeTrailingTrivia.utf8Offset,
        replacement: rewrittenBody
      )
    )

    return functionEdits
  }

  private func extractBodyExpression(from function: FunctionDeclSyntax) -> String? {
    guard let body = function.body else { return nil }

    let statements = body.statements
    guard statements.count == 1, let statement = statements.first else { return nil }

    if let returnStatement = statement.item.as(ReturnStmtSyntax.self),
       let expression = returnStatement.expression
    {
      return expression.trimmedDescription
    }

    if let expression = statement.item.as(ExprSyntax.self) {
      return expression.trimmedDescription
    }

    if let expressionStatement = statement.item.as(ExpressionStmtSyntax.self) {
      return expressionStatement.expression.trimmedDescription
    }

    return nil
  }

  private func functionParameterInfos(from function: FunctionDeclSyntax) -> [FunctionParameterInfo]? {
    var result: [FunctionParameterInfo] = []

    for parameter in function.signature.parameterClause.parameters {
      guard let localName = localParameterName(from: parameter) else { return nil }
      let typeDescription = parameter.type.trimmedDescription
      guard !typeDescription.isEmpty else { return nil }
      result.append(FunctionParameterInfo(localName: localName, typeDescription: typeDescription))
    }

    return result
  }

  private func localParameterName(from parameter: FunctionParameterSyntax) -> String? {
    if let secondName = parameter.secondName?.text, secondName != "_" {
      return secondName
    }
    let firstName = parameter.firstName.text
    guard firstName != "_" else { return nil }
    return firstName
  }

  private func snapshotConfigurationValueType(for infos: [FunctionParameterInfo]) -> String {
    if infos.count == 1 {
      return infos[0].typeDescription
    }
    return "(\(infos.map(\.typeDescription).joined(separator: ", ")))"
  }

  private func normalizeArgumentsExpression(_ expression: String) -> String? {
    let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if trimmed.hasPrefix("[") || trimmed.hasSuffix(")") {
      return trimmed
    }

    if trimmed.hasPrefix("{") {
      return "(\(trimmed))()"
    }

    if isCallableReference(trimmed) {
      return trimmed
    }

    return nil
  }

  private func isCallableReference(_ expression: String) -> Bool {
    let parts = expression.split(separator: ".", omittingEmptySubsequences: false)
    guard !parts.isEmpty else { return false }
    return parts.allSatisfy { part in
      let value = String(part)
      guard let first = value.first else { return false }
      guard first.isLetter || first == "_" else { return false }
      return value.dropFirst().allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
  }

  private func requiresUnsupportedArgumentNamingSkip(
    kind: ParameterizedSnapshotArgument.Kind,
    normalizedArguments: String,
    legacyNameLiteral: String?
  ) -> Bool {
    switch kind {
    case .configurationValues:
      return legacyNameLiteral == nil
    case .configurations:
      guard normalizedArguments.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") else {
        return false
      }

      if normalizedArguments.contains("name: nil") || normalizedArguments.contains("SnapshotConfiguration(value:") {
        return true
      }

      let literalNames = extractSnapshotConfigurationLiteralNames(from: normalizedArguments)
      if literalNames.isEmpty {
        return true
      }

      return Set(literalNames).count != literalNames.count
    }
  }

  private func extractSnapshotConfigurationLiteralNames(from expression: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: #"name:\s*"([^"]*)""#) else {
      return []
    }

    let range = NSRange(expression.startIndex..<expression.endIndex, in: expression)
    return regex.matches(in: expression, range: range).compactMap { match in
      guard match.numberOfRanges > 1,
            let capturedRange = Range(match.range(at: 1), in: expression)
      else {
        return nil
      }
      return String(expression[capturedRange])
    }
  }

  private func rewriteDirectBody(
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

  private func rewriteSwiftUIConfigurationsBody(
    expression: String,
    parameterNames: [String],
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
    let builderIndent = statementIndent + "  "

    let namedSuffix = namedLiteral.map { ", named: \($0)" } ?? ""
    let builderParameters = parameterNames.joined(separator: ", ")

    return """
    {
    \(statementIndent)#expectSnapshot(configuration\(namedSuffix)) { \(builderParameters) in
    \(builderIndent)\(expression)
    \(statementIndent)}
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationsBody(
    expression: String,
    parameterNames: [String],
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
    let extractedValueLine: String
    if parameterNames.count == 1 {
      extractedValueLine = "let \(parameterNames[0]) = configuration.value"
    } else {
      extractedValueLine = "let (\(parameterNames.joined(separator: ", "))) = configuration.value"
    }

    let caseNameExpression = "configuration.name ?? String(describing: configuration.value)"
    let synthesizedName = synthesizedNameExpression(
      legacyNameLiteral: namedLiteral,
      caseNameExpression: caseNameExpression
    )

    return """
    {
    \(statementIndent)\(extractedValueLine)
    \(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: \(synthesizedName))
    \(closingIndent)}
    """
  }

  private func rewriteSwiftUIConfigurationValuesBody(
    expression: String,
    parameterName: String,
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
    let builderIndent = statementIndent + "  "

    let namedSuffix = namedLiteral.map { ", named: \($0)" } ?? ""

    return """
    {
    \(statementIndent)#expectSnapshot(argument: \(parameterName)\(namedSuffix)) { \(parameterName) in
    \(builderIndent)\(expression)
    \(statementIndent)}
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationValuesBody(
    expression: String,
    parameterName: String,
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

    let caseNameExpression = "String(describing: \(parameterName))"
    let synthesizedName = synthesizedNameExpression(
      legacyNameLiteral: namedLiteral,
      caseNameExpression: caseNameExpression
    )

    return """
    {
    \(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: \(synthesizedName))
    \(closingIndent)}
    """
  }

  private func synthesizedNameExpression(
    legacyNameLiteral: String?,
    caseNameExpression: String
  ) -> String {
    if let legacyNameLiteral {
      return "\(legacyNameLiteral) + \"-\" + \(caseNameExpression)"
    }
    return caseNameExpression
  }

  private func makeReason(
    code: String,
    message: String,
    utf8Offset: Int,
    converter: SourceLocationConverter,
    source: String
  ) -> RewriteReason {
    let clampedOffset = max(0, min(utf8Offset, source.utf8.count))
    let location = converter.location(for: AbsolutePosition(utf8Offset: clampedOffset))
    return RewriteReason(code: code, message: message, line: location.line, column: location.column)
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
  private(set) var suiteAttributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []

  init(viewMode: SyntaxTreeViewMode) {
    self.visitor = RewriteCollectorVisitor(viewMode: viewMode)
  }

  private var visitor: RewriteCollectorVisitor

  mutating func walk(_ tree: SourceFileSyntax) {
    visitor.walk(tree)
    suiteAttributeEdits = visitor.suiteAttributeEdits
    legacyFunctions = visitor.legacyFunctions
  }
}

private final class RewriteCollectorVisitor: SyntaxVisitor {
  private(set) var suiteAttributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []

  override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
      return .visitChildren
    }

    if identifier == "SnapshotSuite" {
      suiteAttributeEdits.append(
        TextEdit(
          startUTF8Offset: node.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: node.attributeName.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: "Suite"
        )
      )
    }

    return .visitChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let snapshotAttribute = snapshotTestAttribute(in: node.attributes) else {
      return .visitChildren
    }

    let parsed = parse(snapshotAttribute: snapshotAttribute)
    let legacyFunction = LegacyFunction(
      function: node,
      namedLiteral: parsed.namedLiteral,
      snapshotAttributeNameStartUTF8Offset: snapshotAttribute.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset,
      snapshotAttributeNameEndUTF8Offset: snapshotAttribute.attributeName.endPositionBeforeTrailingTrivia.utf8Offset,
      parameterizedArgument: parsed.parameterizedArgument,
      parseIssue: parsed.parseIssue
    )
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

  private func parse(snapshotAttribute attribute: AttributeSyntax) -> ParsedSnapshotAttribute {
    guard let arguments = attribute.arguments else {
      return ParsedSnapshotAttribute(namedLiteral: nil, parameterizedArgument: nil, parseIssue: nil)
    }

    guard let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
      return ParsedSnapshotAttribute(
        namedLiteral: nil,
        parameterizedArgument: nil,
        parseIssue: AttributeParseIssue(
          code: "unsupported-attribute-arguments",
          message: "Could not parse @SnapshotTest attribute arguments."
        )
      )
    }

    var namedLiteral: String?
    var parameterizedArgument: ParameterizedSnapshotArgument?
    var parseIssue: AttributeParseIssue?

    for argument in labeledArguments {
      if namedLiteral == nil,
         argument.label == nil,
         let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
      {
        namedLiteral = stringLiteral.trimmedDescription
      }

      guard let labelSyntax = argument.label else { continue }
      let label = labelSyntax.text

      let kind: ParameterizedSnapshotArgument.Kind?
      if label == "configurations" {
        kind = .configurations
      } else if label == "configurationValues" {
        kind = .configurationValues
      } else {
        kind = nil
      }

      guard let kind else { continue }

      if parameterizedArgument != nil {
        parseIssue = AttributeParseIssue(
          code: "unsupported-attribute-arguments",
          message: "Multiple parameterized argument labels are not supported."
        )
        continue
      }

      parameterizedArgument = ParameterizedSnapshotArgument(
        kind: kind,
        labelStartUTF8Offset: labelSyntax.positionAfterSkippingLeadingTrivia.utf8Offset,
        labelEndUTF8Offset: labelSyntax.endPositionBeforeTrailingTrivia.utf8Offset,
        expressionStartUTF8Offset: argument.expression.positionAfterSkippingLeadingTrivia.utf8Offset,
        expressionEndUTF8Offset: argument.expression.endPositionBeforeTrailingTrivia.utf8Offset,
        expressionText: argument.expression.trimmedDescription
      )
    }

    return ParsedSnapshotAttribute(
      namedLiteral: namedLiteral,
      parameterizedArgument: parameterizedArgument,
      parseIssue: parseIssue
    )
  }
}

private struct LegacyFunction: Hashable {
  let function: FunctionDeclSyntax
  let namedLiteral: String?
  let snapshotAttributeNameStartUTF8Offset: Int
  let snapshotAttributeNameEndUTF8Offset: Int
  let parameterizedArgument: ParameterizedSnapshotArgument?
  let parseIssue: AttributeParseIssue?
}

private struct FunctionParameterInfo {
  let localName: String
  let typeDescription: String
}

private struct ParsedSnapshotAttribute {
  let namedLiteral: String?
  let parameterizedArgument: ParameterizedSnapshotArgument?
  let parseIssue: AttributeParseIssue?
}

private struct ParameterizedSnapshotArgument: Hashable {
  enum Kind: Hashable {
    case configurations
    case configurationValues
  }

  let kind: Kind
  let labelStartUTF8Offset: Int
  let labelEndUTF8Offset: Int
  let expressionStartUTF8Offset: Int
  let expressionEndUTF8Offset: Int
  let expressionText: String
}

private struct AttributeParseIssue: Hashable {
  let code: String
  let message: String
}

private struct TextEdit: Hashable {
  let startUTF8Offset: Int
  let endUTF8Offset: Int
  let replacement: String
}
