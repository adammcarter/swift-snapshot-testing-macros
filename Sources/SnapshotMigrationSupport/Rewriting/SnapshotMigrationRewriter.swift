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
          let bodyParts = extractBodyParts(from: function)
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

      if let mainActorEdit = mainActorInsertionEditIfNeeded(for: function, source: source) {
        functionEdits.append(mainActorEdit)
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
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          namedLiteral: legacyFunction.namedLiteral,
          body: body,
          source: source
        )
      )
    )

    return functionEdits
  }

  // swiftlint:disable:next cyclomatic_complexity
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
    let snapshotValueType = returnClause.type.trimmedDescription

    guard let body = function.body,
          let bodyParts = extractBodyParts(from: function)
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

    guard var normalizedArguments = normalizeArgumentsExpression(parameterizedArgument.expressionText) else {
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
        startUTF8Offset: returnClause.positionAfterSkippingLeadingTrivia.utf8Offset,
        endUTF8Offset: returnClause.endPositionBeforeTrailingTrivia.utf8Offset,
        replacement: ""
      ),
    ]

    if let mainActorEdit = mainActorInsertionEditIfNeeded(for: function, source: source) {
      functionEdits.append(mainActorEdit)
    }

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
      normalizedArguments = rewriteConfigurationsArgumentsExpression(
        normalizedArguments,
        configurationType: configurationType,
        source: source
      )
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
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterNames: parameterInfos.map(\.localName),
          namedLiteral: legacyFunction.namedLiteral,
          functionName: function.name.text,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationsBody(
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterNames: parameterInfos.map(\.localName),
          namedLiteral: legacyFunction.namedLiteral,
          functionName: function.name.text,
          snapshotValueType: snapshotValueType,
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
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterName: parameterName,
          namedLiteral: legacyFunction.namedLiteral,
          functionName: function.name.text,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationValuesBody(
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterName: parameterName,
          namedLiteral: legacyFunction.namedLiteral,
          functionName: function.name.text,
          snapshotValueType: snapshotValueType,
          body: body,
          source: source
        )
      case .unsupported:
        return nil
      }
    }

    functionEdits.append(
      TextEdit(
        startUTF8Offset: parameterizedArgument.expressionStartUTF8Offset,
        endUTF8Offset: parameterizedArgument.expressionEndUTF8Offset,
        replacement: normalizedArguments
      )
    )

    functionEdits.append(
      TextEdit(
        startUTF8Offset: body.positionAfterSkippingLeadingTrivia.utf8Offset,
        endUTF8Offset: body.endPositionBeforeTrailingTrivia.utf8Offset,
        replacement: rewrittenBody
      )
    )

    return functionEdits
  }

  private func extractBodyParts(from function: FunctionDeclSyntax) -> BodyRewriteParts? {
    guard let body = function.body else { return nil }

    let statements = Array(body.statements)
    guard let terminalStatement = statements.last else { return nil }

    let terminalExpression: String
    if let returnStatement = terminalStatement.item.as(ReturnStmtSyntax.self),
       let expression = returnStatement.expression
    {
      terminalExpression = expression.trimmedDescription
    } else if let expression = terminalStatement.item.as(ExprSyntax.self) {
      guard !containsTopLevelReturn(in: terminalStatement) else { return nil }
      terminalExpression = expression.trimmedDescription
    } else if let expressionStatement = terminalStatement.item.as(ExpressionStmtSyntax.self) {
      guard !containsTopLevelReturn(in: terminalStatement) else { return nil }
      terminalExpression = expressionStatement.expression.trimmedDescription
    } else {
      return nil
    }

    var preludeStatements: [String] = []
    for statement in statements.dropLast() {
      guard !containsTopLevelReturn(in: statement) else { return nil }
      guard let preludeStatement = statementText(for: statement) else { return nil }
      preludeStatements.append(preludeStatement)
    }

    return BodyRewriteParts(
      preludeStatements: preludeStatements,
      terminalExpression: terminalExpression
    )
  }

  private func statementText(for statement: CodeBlockItemSyntax) -> String? {
    let text = statement.item.description.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return nil }
    return text
  }

  private func containsTopLevelReturn(in statement: CodeBlockItemSyntax) -> Bool {
    let detector = TopLevelReturnDetector(viewMode: .sourceAccurate)
    detector.walk(Syntax(statement.item))
    return detector.hasTopLevelReturn
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

  private func containsMainActorAttribute(_ function: FunctionDeclSyntax) -> Bool {
    containsMainActorAttribute(in: function.attributes)
  }

  private func containsMainActorAttribute(in attributes: AttributeListSyntax) -> Bool {
    attributes.contains { attributeElement in
      guard let attribute = attributeElement.as(AttributeSyntax.self) else {
        return false
      }

      return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "MainActor"
    }
  }

  private func mainActorInsertionEdit(
    for function: FunctionDeclSyntax,
    source: String
  ) -> TextEdit {
    let insertionOffset = function.positionAfterSkippingLeadingTrivia.utf8Offset
    let indentation = indentation(atUTF8Offset: insertionOffset, in: source)
    return TextEdit(
      startUTF8Offset: insertionOffset,
      endUTF8Offset: insertionOffset,
      replacement: "@MainActor\n\(indentation)"
    )
  }

  private func mainActorTypeInsertionEditIfNeeded(
    for function: FunctionDeclSyntax,
    source: String
  ) -> TextEdit? {
    guard let enclosingType = enclosingNominalTypeInfo(for: function),
          !enclosingType.hasMainActor
    else {
      return nil
    }

    let indentation = indentation(atUTF8Offset: enclosingType.startUTF8Offset, in: source)
    return TextEdit(
      startUTF8Offset: enclosingType.startUTF8Offset,
      endUTF8Offset: enclosingType.startUTF8Offset,
      replacement: "@MainActor\n\(indentation)"
    )
  }

  private func mainActorInsertionEditIfNeeded(
    for function: FunctionDeclSyntax,
    source: String
  ) -> TextEdit? {
    if let typeEdit = mainActorTypeInsertionEditIfNeeded(for: function, source: source) {
      return typeEdit
    }

    guard enclosingNominalTypeInfo(for: function) == nil,
          !containsMainActorAttribute(function)
    else {
      return nil
    }

    return mainActorInsertionEdit(
      for: function,
      source: source
    )
  }

  private func enclosingNominalTypeInfo(for function: FunctionDeclSyntax) -> EnclosingNominalTypeInfo? {
    var current = Syntax(function).parent
    while let node = current {
      if let structDecl = node.as(StructDeclSyntax.self) {
        return EnclosingNominalTypeInfo(
          startUTF8Offset: structDecl.positionAfterSkippingLeadingTrivia.utf8Offset,
          hasMainActor: containsMainActorAttribute(in: structDecl.attributes)
        )
      }
      if let classDecl = node.as(ClassDeclSyntax.self) {
        return EnclosingNominalTypeInfo(
          startUTF8Offset: classDecl.positionAfterSkippingLeadingTrivia.utf8Offset,
          hasMainActor: containsMainActorAttribute(in: classDecl.attributes)
        )
      }
      if let actorDecl = node.as(ActorDeclSyntax.self) {
        return EnclosingNominalTypeInfo(
          startUTF8Offset: actorDecl.positionAfterSkippingLeadingTrivia.utf8Offset,
          hasMainActor: containsMainActorAttribute(in: actorDecl.attributes)
        )
      }
      if let enumDecl = node.as(EnumDeclSyntax.self) {
        return EnclosingNominalTypeInfo(
          startUTF8Offset: enumDecl.positionAfterSkippingLeadingTrivia.utf8Offset,
          hasMainActor: containsMainActorAttribute(in: enumDecl.attributes)
        )
      }

      current = node.parent
    }

    return nil
  }

  private func normalizeArgumentsExpression(_ expression: String) -> String? {
    let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if trimmed.hasPrefix("{") {
      return "(\(trimmed))()"
    }

    return trimmed
  }

  private func expandSnapshotConfigurationInitializerShorthand(in expression: String) -> String {
    guard expression.contains(".init") else { return expression }
    guard let regex = try? NSRegularExpression(pattern: #"\.init\s*\((?=\s*(?:name:|value:))"#) else {
      return expression
    }

    let range = NSRange(expression.startIndex..<expression.endIndex, in: expression)
    return regex.stringByReplacingMatches(
      in: expression,
      range: range,
      withTemplate: "SnapshotConfiguration("
    )
  }

  private func rewriteConfigurationsArgumentsExpression(
    _ expression: String,
    configurationType: String,
    source: String
  ) -> String {
    var rewritten = expandSnapshotConfigurationInitializerShorthand(in: expression)
    rewritten = invokeZeroArgumentFunctionReferenceIfNeeded(rewritten, source: source)
    rewritten = addConfigurationInitializerTypeContext(
      to: rewritten,
      configurationType: configurationType
    )

    if shouldAddConfigurationsTypeContext(to: rewritten) {
      return "(\(rewritten)) as [SnapshotConfiguration<\(configurationType)>]"
    }

    return rewritten
  }

  private func invokeZeroArgumentFunctionReferenceIfNeeded(_ expression: String, source: String) -> String {
    let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let identifier = bareIdentifierName(in: trimmed),
          sourceContainsZeroArgumentFunction(named: identifier, source: source)
    else {
      return expression
    }

    return "\(identifier)()"
  }

  private func shouldAddConfigurationsTypeContext(to expression: String) -> Bool {
    let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.contains("nil")
  }

  private func addConfigurationInitializerTypeContext(
    to expression: String,
    configurationType: String
  ) -> String {
    expression.replacingOccurrences(
      of: "SnapshotConfiguration(",
      with: "SnapshotConfiguration<\(configurationType)>("
    )
  }

  private func bareIdentifierName(in expression: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: #"^[A-Za-z_][A-Za-z0-9_]*$"#) else {
      return nil
    }

    let range = NSRange(expression.startIndex..<expression.endIndex, in: expression)
    guard regex.firstMatch(in: expression, range: range) != nil else {
      return nil
    }

    return expression
  }

  private func sourceContainsZeroArgumentFunction(named name: String, source: String) -> Bool {
    let escapedName = NSRegularExpression.escapedPattern(for: name)
    guard let regex = try? NSRegularExpression(pattern: #"(?m)\bfunc\s+\#(escapedName)\s*\(\s*\)"#) else {
      return false
    }

    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    return regex.firstMatch(in: source, range: range) != nil
  }

  private func requiresUnsupportedArgumentNamingSkip(
    kind: ParameterizedSnapshotArgument.Kind,
    normalizedArguments: String,
    legacyNameLiteral _: String?
  ) -> Bool {
    switch kind {
    case .configurationValues:
      return false
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
    preludeStatements: [String],
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
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(prelude)\(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue\(namedSuffix))
    \(closingIndent)}
    """
  }

  private func rewriteSwiftUIConfigurationsBody(
    expression: String,
    preludeStatements: [String],
    parameterNames: [String],
    namedLiteral: String?,
    functionName: String,
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
    let snapshotNameExpression = legacyCompatibleSnapshotNameExpression(
      caseNameExpression: caseNameExpression,
      legacyNameLiteral: namedLiteral,
      functionName: functionName
    )
    let snapshotNameLine = "let snapshotName = \(snapshotNameExpression)"
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(snapshotNameLine)
    \(statementIndent)\(extractedValueLine)
    \(prelude)\(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: snapshotName)
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationsBody(
    expression: String,
    preludeStatements: [String],
    parameterNames: [String],
    namedLiteral: String?,
    functionName: String,
    snapshotValueType: String,
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
    let snapshotNameExpression = legacyCompatibleSnapshotNameExpression(
      caseNameExpression: caseNameExpression,
      legacyNameLiteral: namedLiteral,
      functionName: functionName
    )
    let snapshotNameLine = "let snapshotName = \(snapshotNameExpression)"
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(snapshotNameLine)
    \(statementIndent)\(extractedValueLine)
    \(prelude)\(statementIndent)let snapshotValue: \(snapshotValueType) = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: snapshotName)
    \(closingIndent)}
    """
  }

  private func rewriteSwiftUIConfigurationValuesBody(
    expression: String,
    preludeStatements: [String],
    parameterName: String,
    namedLiteral: String?,
    functionName: String,
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
    let snapshotNameExpression = legacyCompatibleSnapshotNameExpression(
      caseNameExpression: caseNameExpression,
      legacyNameLiteral: namedLiteral,
      functionName: functionName
    )
    let snapshotNameLine = "let snapshotName = \(snapshotNameExpression)"
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(snapshotNameLine)
    \(prelude)\(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: snapshotName)
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationValuesBody(
    expression: String,
    preludeStatements: [String],
    parameterName: String,
    namedLiteral: String?,
    functionName: String,
    snapshotValueType: String,
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
    let snapshotNameExpression = legacyCompatibleSnapshotNameExpression(
      caseNameExpression: caseNameExpression,
      legacyNameLiteral: namedLiteral,
      functionName: functionName
    )
    let snapshotNameLine = "let snapshotName = \(snapshotNameExpression)"
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(snapshotNameLine)
    \(prelude)\(statementIndent)let snapshotValue: \(snapshotValueType) = \(expression)
    \(statementIndent)#expectSnapshot(snapshotValue, named: snapshotName)
    \(closingIndent)}
    """
  }

  private func renderStatements(_ statements: [String], indentation: String) -> String {
    guard !statements.isEmpty else { return "" }
    let rendered = statements
      .map { renderMultiline($0, indentation: indentation) }
      .joined(separator: "\n")
    return "\(rendered)\n"
  }

  private func renderMultiline(_ statement: String, indentation: String) -> String {
    statement
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map { "\(indentation)\($0)" }
      .joined(separator: "\n")
  }

  private func legacyCompatibleSnapshotNameExpression(
    caseNameExpression: String,
    legacyNameLiteral: String?,
    functionName: String
  ) -> String {
    let displayNameExpression = snapshotDisplayNameExpression(
      legacyNameLiteral: legacyNameLiteral,
      functionName: functionName
    )
    return "(\(caseNameExpression)) + \"/\" + (\(displayNameExpression))"
  }

  private func snapshotDisplayNameExpression(
    legacyNameLiteral: String?,
    functionName: String
  ) -> String {
    if let legacyNameLiteral {
      return legacyNameLiteral
    }
    return swiftStringLiteral(functionName)
  }

  private func swiftStringLiteral(_ value: String) -> String {
    let escaped = value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
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

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    removeDuplicateSuiteAttributeIfNeeded(in: node.attributes)
    return .visitChildren
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    removeDuplicateSuiteAttributeIfNeeded(in: node.attributes)
    return .visitChildren
  }

  override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    removeDuplicateSuiteAttributeIfNeeded(in: node.attributes)
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    removeDuplicateSuiteAttributeIfNeeded(in: node.attributes)
    return .visitChildren
  }

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

  private func removeDuplicateSuiteAttributeIfNeeded(in attributes: AttributeListSyntax) {
    let attributeSyntaxes = attributes.compactMap { $0.as(AttributeSyntax.self) }

    let hasSnapshotSuite = attributeSyntaxes.contains {
      $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "SnapshotSuite"
    }
    let hasSuite = attributeSyntaxes.contains {
      $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "Suite"
    }

    guard hasSnapshotSuite, hasSuite else { return }

    for attribute in attributeSyntaxes where attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "Suite" {
      suiteAttributeEdits.append(
        TextEdit(
          startUTF8Offset: attribute.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: attribute.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: ""
        )
      )
    }
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

private struct EnclosingNominalTypeInfo {
  let startUTF8Offset: Int
  let hasMainActor: Bool
}

private struct BodyRewriteParts {
  let preludeStatements: [String]
  let terminalExpression: String
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

private final class TopLevelReturnDetector: SyntaxVisitor {
  private(set) var hasTopLevelReturn = false
  private var nestedCallableDepth = 0

  // swiftlint:disable unused_parameter
  override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    nestedCallableDepth += 1
    return .visitChildren
  }

  override func visitPost(_ node: ClosureExprSyntax) {
    nestedCallableDepth = max(0, nestedCallableDepth - 1)
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    nestedCallableDepth += 1
    return .visitChildren
  }

  override func visitPost(_ node: FunctionDeclSyntax) {
    nestedCallableDepth = max(0, nestedCallableDepth - 1)
  }

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    nestedCallableDepth += 1
    return .visitChildren
  }

  override func visitPost(_ node: InitializerDeclSyntax) {
    nestedCallableDepth = max(0, nestedCallableDepth - 1)
  }

  override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    nestedCallableDepth += 1
    return .visitChildren
  }

  override func visitPost(_ node: SubscriptDeclSyntax) {
    nestedCallableDepth = max(0, nestedCallableDepth - 1)
  }

  override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    nestedCallableDepth += 1
    return .visitChildren
  }

  override func visitPost(_ node: AccessorDeclSyntax) {
    nestedCallableDepth = max(0, nestedCallableDepth - 1)
  }

  override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
    if nestedCallableDepth == 0 {
      hasTopLevelReturn = true
    }
    return .skipChildren
  }
}
// swiftlint:enable unused_parameter
