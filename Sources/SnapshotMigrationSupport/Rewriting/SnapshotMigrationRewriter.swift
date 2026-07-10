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

/// The rewrite outcome of a single legacy snapshot declaration found in a file.
///
/// Files can hold any number of declarations; the runner aggregates these outcomes so the
/// report counts declarations, not files. A qualified attribute (`@Module.SnapshotTest`)
/// is reported as a skipped declaration whose name is unknown.
public struct RewriteDeclarationOutcome: Equatable {
  public enum Resolution: Equatable {
    /// The declaration produced safe edits and can be migrated.
    case migratable
    /// The declaration cannot be migrated automatically; `reasons` explains why.
    case skipped
  }

  public let name: String
  public let line: Int
  public let resolution: Resolution
  public let reasons: [RewriteReason]

  public init(name: String, line: Int, resolution: Resolution, reasons: [RewriteReason]) {
    self.name = name
    self.line = line
    self.resolution = resolution
    self.reasons = reasons
  }
}

public struct RewriteResult: Equatable {
  public let output: String
  public let reasons: [RewriteReason]
  public let changed: Bool
  /// Per-declaration outcomes for every legacy snapshot declaration found in the file.
  /// Empty when the scan matched only comments or string literals (no real declarations).
  public let declarations: [RewriteDeclarationOutcome]

  public init(
    output: String,
    reasons: [RewriteReason],
    changed: Bool,
    declarations: [RewriteDeclarationOutcome] = []
  ) {
    self.output = output
    self.reasons = reasons
    self.changed = changed
    self.declarations = declarations
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
    var declarations: [RewriteDeclarationOutcome] = []

    for qualifiedAttribute in collector.qualifiedSnapshotAttributes {
      let reason = makeReason(
        code: "qualified-attribute-unsupported",
        message: "Module-qualified @\(qualifiedAttribute.name) attributes are not supported "
          + "for automatic migration; migrate this declaration manually.",
        utf8Offset: qualifiedAttribute.utf8Offset,
        converter: converter,
        source: source
      )
      reasons.append(reason)
      declarations.append(
        RewriteDeclarationOutcome(
          name: "<unknown>",
          line: reason.line,
          resolution: .skipped,
          reasons: [reason]
        )
      )
    }

    for legacyFunction in collector.legacyFunctions {
      let functionName = legacyFunction.function.name.text
      let functionPosition = legacyFunction.function.positionAfterSkippingLeadingTrivia
      let functionLine = converter.location(for: functionPosition).line

      if let parseIssue = legacyFunction.parseIssue {
        let reason = makeReason(
          code: parseIssue.code,
          message: parseIssue.message,
          utf8Offset: legacyFunction.snapshotAttributeNameStartUTF8Offset,
          converter: converter,
          source: source
        )
        reasons.append(reason)
        declarations.append(
          RewriteDeclarationOutcome(
            name: functionName,
            line: functionLine,
            resolution: .skipped,
            reasons: [reason]
          )
        )
        continue
      }

      let reasonCountBeforeFunction = reasons.count
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

      declarations.append(
        RewriteDeclarationOutcome(
          name: functionName,
          line: functionLine,
          resolution: functionEdits == nil ? .skipped : .migratable,
          reasons: Array(reasons[reasonCountBeforeFunction...])
        )
      )
    }

    let output = apply(edits: edits, to: source)
    return RewriteResult(
      output: output,
      reasons: reasons,
      changed: output != source,
      declarations: declarations
    )
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

    let displayNameExpression = parameterizedDisplayNameExpression(for: legacyFunction)

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

      if configurationsExpressionHasUnsupportedInitShorthand(in: normalizedArguments) {
        reasons.append(
          makeReason(
            code: "unsupported-configuration-shape",
            message: "`configurations:` element uses an initializer shorthand that cannot be safely typed.",
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
          displayNameExpression: displayNameExpression,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationsBody(
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterNames: parameterInfos.map(\.localName),
          displayNameExpression: displayNameExpression,
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
          displayNameExpression: displayNameExpression,
          body: body,
          source: source
        )
      case .uiKitOrAppKit:
        rewrittenBody = rewriteDirectConfigurationValuesBody(
          expression: bodyParts.terminalExpression,
          preludeStatements: bodyParts.preludeStatements,
          parameterName: parameterName,
          displayNameExpression: displayNameExpression,
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

    guard let terminalExpression = terminalExpressionText(for: terminalStatement) else {
      return nil
    }

    var preludeStatements: [String] = []
    for statement in statements.dropLast() {
      guard !containsTopLevelReturn(in: statement) else { return nil }
      guard let preludeStatement = statementText(for: statement) else { return nil }
      preludeStatements.append(preludeStatement)
    }

    // Comments attached above the terminal statement would otherwise vanish with the
    // `return` keyword; re-emit them directly above the rewritten terminal line.
    if let terminalComments = leadingCommentLines(for: terminalStatement) {
      preludeStatements.append(terminalComments)
    }

    return BodyRewriteParts(
      preludeStatements: preludeStatements,
      terminalExpression: terminalExpression
    )
  }

  private func terminalExpressionText(for terminalStatement: CodeBlockItemSyntax) -> String? {
    if let returnStatement = terminalStatement.item.as(ReturnStmtSyntax.self),
       let expression = returnStatement.expression
    {
      return expression.trimmedDescription
    }
    if let expression = terminalStatement.item.as(ExprSyntax.self) {
      guard !containsTopLevelReturn(in: terminalStatement) else { return nil }
      return expression.trimmedDescription
    }
    if let expressionStatement = terminalStatement.item.as(ExpressionStmtSyntax.self) {
      guard !containsTopLevelReturn(in: terminalStatement) else { return nil }
      return expressionStatement.expression.trimmedDescription
    }
    return nil
  }

  private func statementText(for statement: CodeBlockItemSyntax) -> String? {
    let lines = normalizedLines(
      from: statement.description,
      baseIndentation: baseIndentation(of: statement)
    )
    let text = lines.joined(separator: "\n")
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return text
  }

  /// The comment lines (and their blank-line structure) attached above a statement, dedented
  /// so the renderer can re-indent them without duplicating whitespace. `nil` when the
  /// statement carries no comment trivia.
  private func leadingCommentLines(for statement: CodeBlockItemSyntax) -> String? {
    guard statement.leadingTrivia.contains(where: isCommentPiece) else { return nil }

    var lines = normalizedLines(
      from: statement.leadingTrivia.description,
      baseIndentation: baseIndentation(of: statement)
    )
    // The final trivia line is the statement's own indentation, not a comment line.
    if let last = lines.last, last.isEmpty {
      lines.removeLast()
    }
    guard !lines.isEmpty else { return nil }
    return lines.joined(separator: "\n")
  }

  /// Splits raw source text into lines, drops the remnant of the previous line's terminating
  /// newline, strips the statement's own indentation from each line (preserving deeper
  /// relative indentation), and trims trailing whitespace.
  private func normalizedLines(from text: String, baseIndentation: String) -> [String] {
    var lines = text
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)

    if lines.count > 1,
       let first = lines.first,
       first.trimmingCharacters(in: .whitespaces).isEmpty
    {
      lines.removeFirst()
    }

    return lines.map { line in
      trimmingTrailingWhitespace(removingIndentation(line, upTo: baseIndentation))
    }
  }

  /// The whitespace column the statement starts at: the last leading-trivia line, which is
  /// the indentation between the preceding newline and the statement's first token.
  private func baseIndentation(of statement: CodeBlockItemSyntax) -> String {
    let leadingText = statement.leadingTrivia.description
    guard
      let lastLine = leadingText.split(separator: "\n", omittingEmptySubsequences: false).last,
      lastLine.allSatisfy({ $0 == " " || $0 == "\t" })
    else {
      return ""
    }
    return String(lastLine)
  }

  private func removingIndentation(_ line: String, upTo indentation: String) -> String {
    var remaining = Substring(line)
    var budget = indentation.count
    while budget > 0, let first = remaining.first, first == " " || first == "\t" {
      remaining.removeFirst()
      budget -= 1
    }
    return String(remaining)
  }

  private func trimmingTrailingWhitespace(_ line: String) -> String {
    var trimmed = Substring(line)
    while let last = trimmed.last, last == " " || last == "\t" {
      trimmed.removeLast()
    }
    return String(trimmed)
  }

  private func isCommentPiece(_ piece: TriviaPiece) -> Bool {
    switch piece {
    case .lineComment, .blockComment, .docLineComment, .docBlockComment:
      return true
    default:
      return false
    }
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

  private func rewriteConfigurationsArgumentsExpression(
    _ expression: String,
    configurationType: String,
    source: String
  ) -> String {
    var rewritten = rewriteConfigurationElementInitializers(
      in: expression,
      configurationType: configurationType
    )
    rewritten = invokeZeroArgumentFunctionReferenceIfNeeded(rewritten, source: source)

    if shouldAddConfigurationsTypeContext(to: rewritten) {
      return "(\(rewritten)) as [SnapshotConfiguration<\(configurationType)>]"
    }

    return rewritten
  }

  /// Rewrites configuration constructions in element position — direct elements of the
  /// top-level array literal and result expressions of closures passed to the top-level call
  /// (the `.map { ... }` shape) — into explicitly typed `SnapshotConfiguration<T>(...)` calls:
  ///
  /// - a bare `.init(name:...)` / `.init(value:...)` shorthand becomes `SnapshotConfiguration<T>(...)`
  /// - an explicit `SnapshotConfiguration(...)` / `Module.SnapshotConfiguration(...)` gains `<T>`
  ///
  /// Everything else is left byte-identical: receiver-qualified initializers
  /// (`User.init(name:)`), initializers nested inside element values, string-literal contents,
  /// and types whose names merely end in `SnapshotConfiguration`.
  private func rewriteConfigurationElementInitializers(
    in expression: String,
    configurationType: String
  ) -> String {
    guard expression.contains(".init") || expression.contains("SnapshotConfiguration") else {
      return expression
    }

    var parser = Parser(expression)
    let parsed = ExprSyntax.parse(from: &parser)
    guard !parsed.hasError, parsed.description == expression else { return expression }

    var edits: [TextEdit] = []
    for element in configurationElementExpressions(of: parsed) {
      guard let call = element.as(FunctionCallExprSyntax.self),
            let rewrite = configurationCalleeRewrite(for: call)
      else {
        continue
      }

      let callee = call.calledExpression
      switch rewrite {
      case .replaceBareInitializerShorthand:
        edits.append(
          TextEdit(
            startUTF8Offset: callee.positionAfterSkippingLeadingTrivia.utf8Offset,
            endUTF8Offset: callee.endPositionBeforeTrailingTrivia.utf8Offset,
            replacement: "SnapshotConfiguration<\(configurationType)>"
          )
        )
      case .specializeConfigurationReference:
        let insertionOffset = callee.endPositionBeforeTrailingTrivia.utf8Offset
        edits.append(
          TextEdit(
            startUTF8Offset: insertionOffset,
            endUTF8Offset: insertionOffset,
            replacement: "<\(configurationType)>"
          )
        )
      }
    }

    guard !edits.isEmpty else { return expression }
    return apply(edits: edits, to: expression)
  }

  /// The expressions occupying configuration-element position within a `configurations:`
  /// argument: the direct elements of a top-level array literal, or — for the
  /// `<sequence>.map { ... }` shape — the result expressions of closures passed to the
  /// top-level call, including result expressions reachable only through control flow
  /// (terminal `if`/`switch`/ternary expressions, `return`s nested in `guard`/`if`/`switch`),
  /// and the elements of an array literal in result position.
  private func configurationElementExpressions(of root: ExprSyntax) -> [ExprSyntax] {
    if let arrayExpression = root.as(ArrayExprSyntax.self) {
      return arrayExpression.elements.map { ExprSyntax($0.expression) }
    }

    guard let call = root.as(FunctionCallExprSyntax.self) else { return [] }

    var closures: [ClosureExprSyntax] = call.arguments.compactMap {
      $0.expression.as(ClosureExprSyntax.self)
    }
    if let trailingClosure = call.trailingClosure {
      closures.append(trailingClosure)
    }

    var resultExpressions: [ExprSyntax] = []
    for closure in closures {
      collectConfigurationResultExpressions(in: closure.statements, into: &resultExpressions)
    }

    return resultExpressions.flatMap { result -> [ExprSyntax] in
      if let arrayExpression = result.as(ArrayExprSyntax.self) {
        return arrayExpression.elements.map { ExprSyntax($0.expression) }
      }
      return [result]
    }
  }

  /// Walks a closure/branch body collecting every expression whose value becomes a configuration
  /// element: the implicit final expression, and any `return`ed expression — descending through
  /// `guard`/`if`/`switch` statements and `if`/`switch`/ternary *expressions* so element-position
  /// `.init(...)` shorthands reachable only via control flow are still found (and later typed).
  private func collectConfigurationResultExpressions(
    in statements: CodeBlockItemListSyntax,
    into results: inout [ExprSyntax]
  ) {
    guard !statements.isEmpty else { return }
    let lastIndex = statements.index(before: statements.endIndex)
    for index in statements.indices {
      let statement = statements[index]
      let isLast = index == lastIndex

      if let returnStatement = statement.item.as(ReturnStmtSyntax.self),
         let returnedExpression = returnStatement.expression
      {
        addConfigurationResultExpression(returnedExpression, into: &results)
        continue
      }
      if let guardStatement = statement.item.as(GuardStmtSyntax.self) {
        collectConfigurationResultExpressions(in: guardStatement.body.statements, into: &results)
        continue
      }

      // A standalone `if`/`switch` is stored as `.stmt(ExpressionStmtSyntax)`; a plain final
      // expression is stored as `.expr`. Unwrap both to the underlying expression.
      let expression: ExprSyntax?
      if let expressionStatement = statement.item.as(ExpressionStmtSyntax.self) {
        expression = expressionStatement.expression
      } else {
        expression = statement.item.as(ExprSyntax.self)
      }

      guard let expression else { continue }

      // `if`/`switch` (whether statement or terminal expression) carry their own branch results;
      // any other expression only counts when it is the closure's implicit final result.
      if expression.is(IfExprSyntax.self) || expression.is(SwitchExprSyntax.self) || isLast {
        addConfigurationResultExpression(expression, into: &results)
      }
    }
  }

  /// Records a result expression, descending through control-flow *expressions* (`if`/`switch`/
  /// ternary) so the leaf configuration expressions in each branch are collected individually.
  private func addConfigurationResultExpression(
    _ expression: ExprSyntax,
    into results: inout [ExprSyntax]
  ) {
    if let ifExpression = expression.as(IfExprSyntax.self) {
      collectConfigurationResultExpressions(in: ifExpression.body.statements, into: &results)
      switch ifExpression.elseBody {
      case .codeBlock(let block):
        collectConfigurationResultExpressions(in: block.statements, into: &results)
      case .ifExpr(let nestedIf):
        addConfigurationResultExpression(ExprSyntax(nestedIf), into: &results)
      case nil:
        break
      }
    } else if let switchExpression = expression.as(SwitchExprSyntax.self) {
      for caseItem in switchExpression.cases {
        if let switchCase = caseItem.as(SwitchCaseSyntax.self) {
          collectConfigurationResultExpressions(in: switchCase.statements, into: &results)
        }
      }
    } else if let ternary = expression.as(TernaryExprSyntax.self) {
      addConfigurationResultExpression(ternary.thenExpression, into: &results)
      addConfigurationResultExpression(ternary.elseExpression, into: &results)
    } else {
      results.append(expression)
    }
  }

  /// True when the configurations expression carries an element-position bare `.init(...)`
  /// shorthand the rewriter cannot type (unrecognized first label), which would otherwise be
  /// emitted as ambiguous, non-compiling output. Element-position only, so contextual `.init`
  /// nested inside a configuration *value* is not implicated.
  private func configurationsExpressionHasUnsupportedInitShorthand(in expression: String) -> Bool {
    guard expression.contains(".init") else { return false }

    var parser = Parser(expression)
    let parsed = ExprSyntax.parse(from: &parser)
    guard !parsed.hasError, parsed.description == expression else { return false }

    for element in configurationElementExpressions(of: parsed) {
      guard let call = element.as(FunctionCallExprSyntax.self),
            let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil,
            memberAccess.declName.baseName.text == "init"
      else {
        continue
      }
      if configurationCalleeRewrite(for: call) == nil {
        return true
      }
    }

    return false
  }

  private enum ConfigurationCalleeRewrite {
    /// `.init(name:...)` → `SnapshotConfiguration<T>(name:...)`
    case replaceBareInitializerShorthand
    /// `SnapshotConfiguration(...)` / `Module.SnapshotConfiguration(...)` → add `<T>`
    case specializeConfigurationReference
  }

  private func configurationCalleeRewrite(
    for call: FunctionCallExprSyntax
  ) -> ConfigurationCalleeRewrite? {
    if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
      if memberAccess.base == nil,
         memberAccess.declName.baseName.text == "init",
         let firstLabel = call.arguments.first?.label?.text,
         firstLabel == "name" || firstLabel == "value"
      {
        return .replaceBareInitializerShorthand
      }
      if memberAccess.declName.baseName.text == "SnapshotConfiguration" {
        return .specializeConfigurationReference
      }
      return nil
    }

    if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self),
       reference.baseName.text == "SnapshotConfiguration"
    {
      return .specializeConfigurationReference
    }

    return nil
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

  /*
   Parameterized bodies route the case naming through the native configuration machinery:
   `#expectSnapshot(<configuration>, named: <legacy display name>) { _ in snapshotValue }`
   reproduces the legacy artifact layout
   `__Snapshots__/<TestFile>/<display>/<case>_<display>_<size>_<theme>` exactly, because the
   assertion pipeline scopes configuration-named tests into a folder named after the display
   name and prefixes the file name with the configuration name.

   The configuration is always captured as `snapshotConfiguration` before any other rewritten
   statement so later statements (value extraction, prelude) cannot shadow it.
   */

  private func rewriteSwiftUIConfigurationsBody(
    expression: String,
    preludeStatements: [String],
    parameterNames: [String],
    displayNameExpression: String,
    body: CodeBlockSyntax,
    source: String
  ) -> String {
    let closingIndent = indentation(atUTF8Offset: body.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset, in: source)
    let statementIndent = statementIndentation(for: body, closingIndent: closingIndent, source: source)
    let extractedValueLine = configurationValueExtractionLine(parameterNames: parameterNames)
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)let snapshotConfiguration = configuration
    \(statementIndent)\(extractedValueLine)
    \(prelude)\(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)\(configurationAssertionLine(displayNameExpression: displayNameExpression))
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationsBody(
    expression: String,
    preludeStatements: [String],
    parameterNames: [String],
    displayNameExpression: String,
    snapshotValueType: String,
    body: CodeBlockSyntax,
    source: String
  ) -> String {
    let closingIndent = indentation(atUTF8Offset: body.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset, in: source)
    let statementIndent = statementIndentation(for: body, closingIndent: closingIndent, source: source)
    let extractedValueLine = configurationValueExtractionLine(parameterNames: parameterNames)
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)let snapshotConfiguration = configuration
    \(statementIndent)\(extractedValueLine)
    \(prelude)\(statementIndent)let snapshotValue: \(snapshotValueType) = \(expression)
    \(statementIndent)\(configurationAssertionLine(displayNameExpression: displayNameExpression))
    \(closingIndent)}
    """
  }

  private func rewriteSwiftUIConfigurationValuesBody(
    expression: String,
    preludeStatements: [String],
    parameterName: String,
    displayNameExpression: String,
    body: CodeBlockSyntax,
    source: String
  ) -> String {
    let closingIndent = indentation(atUTF8Offset: body.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset, in: source)
    let statementIndent = statementIndentation(for: body, closingIndent: closingIndent, source: source)
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(configurationValuesConfigurationLine(parameterName: parameterName))
    \(prelude)\(statementIndent)let snapshotValue = \(expression)
    \(statementIndent)\(configurationAssertionLine(displayNameExpression: displayNameExpression))
    \(closingIndent)}
    """
  }

  private func rewriteDirectConfigurationValuesBody(
    expression: String,
    preludeStatements: [String],
    parameterName: String,
    displayNameExpression: String,
    snapshotValueType: String,
    body: CodeBlockSyntax,
    source: String
  ) -> String {
    let closingIndent = indentation(atUTF8Offset: body.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset, in: source)
    let statementIndent = statementIndentation(for: body, closingIndent: closingIndent, source: source)
    let prelude = renderStatements(preludeStatements, indentation: statementIndent)

    return """
    {
    \(statementIndent)\(configurationValuesConfigurationLine(parameterName: parameterName))
    \(prelude)\(statementIndent)let snapshotValue: \(snapshotValueType) = \(expression)
    \(statementIndent)\(configurationAssertionLine(displayNameExpression: displayNameExpression))
    \(closingIndent)}
    """
  }

  private func statementIndentation(
    for body: CodeBlockSyntax,
    closingIndent: String,
    source: String
  ) -> String {
    body
      .statements
      .first
      .map { indentation(atUTF8Offset: $0.positionAfterSkippingLeadingTrivia.utf8Offset, in: source) }
      ?? (closingIndent + "  ")
  }

  private func configurationValueExtractionLine(parameterNames: [String]) -> String {
    if parameterNames.count == 1 {
      return "let \(parameterNames[0]) = configuration.value"
    }
    return "let (\(parameterNames.joined(separator: ", "))) = configuration.value"
  }

  /// Rebuilds the configuration the legacy runtime derived for `configurationValues:`
  /// arguments: `SnapshotConfiguration(name: "\(value)", value: value)` — the exact
  /// `"\(value)"` stringification legacy used, so derived case names stay byte-identical.
  private func configurationValuesConfigurationLine(parameterName: String) -> String {
    "let snapshotConfiguration = SnapshotConfiguration(name: \"\\(\(parameterName))\", value: \(parameterName))"
  }

  private func configurationAssertionLine(displayNameExpression: String) -> String {
    "#expectSnapshot(snapshotConfiguration, named: \(displayNameExpression)) { _ in snapshotValue }"
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
      .map { $0.isEmpty ? "" : "\(indentation)\($0)" }
      .joined(separator: "\n")
  }

  /// Resolves the display-name expression for parameterized rewrites using the exact legacy
  /// fallback chain: test display name → enclosing suite display name → function name.
  ///
  /// Interpolated display-name literals are skipped just like the legacy macro did (it read
  /// `representedLiteralValue`, which is `nil` for interpolations, and fell through).
  private func parameterizedDisplayNameExpression(for legacyFunction: LegacyFunction) -> String {
    if legacyFunction.namedLiteralIsPlain, let namedLiteral = legacyFunction.namedLiteral {
      return namedLiteral
    }

    if let suiteDisplayNameLiteral = legacyFunction.suiteDisplayNameLiteral {
      return suiteDisplayNameLiteral
    }

    return swiftStringLiteral(unescapedIdentifierText(legacyFunction.function.name.text))
  }

  /// Mirrors the legacy macro's `identifierDisplayName`, which strips backticks from escaped
  /// identifiers before using the function name as the display name.
  private func unescapedIdentifierText(_ identifier: String) -> String {
    guard identifier.count >= 2, identifier.hasPrefix("`"), identifier.hasSuffix("`") else {
      return identifier
    }

    return String(identifier.dropFirst().dropLast())
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

struct QualifiedSnapshotAttribute: Equatable {
  let name: String
  let utf8Offset: Int
}

private struct RewriteCollector {
  private(set) var suiteAttributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []
  private(set) var qualifiedSnapshotAttributes: [QualifiedSnapshotAttribute] = []

  init(viewMode: SyntaxTreeViewMode) {
    self.visitor = RewriteCollectorVisitor(viewMode: viewMode)
  }

  private var visitor: RewriteCollectorVisitor

  mutating func walk(_ tree: SourceFileSyntax) {
    visitor.walk(tree)
    suiteAttributeEdits = visitor.suiteAttributeEdits
    legacyFunctions = visitor.legacyFunctions
    qualifiedSnapshotAttributes = visitor.qualifiedSnapshotAttributes
  }
}

private final class RewriteCollectorVisitor: SyntaxVisitor {
  private(set) var suiteAttributeEdits: [TextEdit] = []
  private(set) var legacyFunctions: [LegacyFunction] = []
  private(set) var qualifiedSnapshotAttributes: [QualifiedSnapshotAttribute] = []

  /// `@SnapshotSuite` attributes the dedup logic deleted outright (because an argument-carrying
  /// `@Suite` survives on the same declaration); these must not also receive a rename edit.
  private var suppressedSnapshotSuiteRenameOffsets: Set<Int> = []

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
      // Module-qualified legacy attributes (e.g. `@SnapshotsModule.SnapshotTest`) are not
      // rewritable by the identifier-based matching below; record them so the migration
      // surfaces an explicit skip reason instead of silently reporting the file unchanged.
      if let memberName = node.attributeName.as(MemberTypeSyntax.self)?.name.trimmed.text,
        memberName == "SnapshotSuite" || memberName == "SnapshotTest"
      {
        qualifiedSnapshotAttributes.append(
          QualifiedSnapshotAttribute(
            name: memberName,
            utf8Offset: node.positionAfterSkippingLeadingTrivia.utf8Offset
          )
        )
      }
      return .visitChildren
    }

    if identifier == "SnapshotSuite",
       !suppressedSnapshotSuiteRenameOffsets.contains(
         node.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset
       )
    {
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

    let snapshotSuiteAttributes = attributeSyntaxes.filter {
      $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "SnapshotSuite"
    }
    let suiteAttributes = attributeSyntaxes.filter {
      $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "Suite"
    }

    guard !snapshotSuiteAttributes.isEmpty, !suiteAttributes.isEmpty else { return }

    guard let argumentCarryingSuite = suiteAttributes.first(where: { $0.arguments != nil }) else {
      // Every duplicate `@Suite` is bare: delete them all and let the `@SnapshotSuite` rename
      // supply the surviving `@Suite`, keeping the legacy attribute's arguments intact.
      for attribute in suiteAttributes {
        suiteAttributeEdits.append(
          TextEdit(
            startUTF8Offset: attribute.positionAfterSkippingLeadingTrivia.utf8Offset,
            endUTF8Offset: attribute.endPositionBeforeTrailingTrivia.utf8Offset,
            replacement: ""
          )
        )
      }
      return
    }

    // The pre-existing `@Suite` carries arguments (display name and/or traits) that a wholesale
    // delete would silently destroy. Keep that attribute, delete the legacy `@SnapshotSuite`
    // instead, and fold the legacy snapshot traits into the surviving argument list.
    for bareSuite in suiteAttributes where bareSuite.arguments == nil {
      suiteAttributeEdits.append(
        TextEdit(
          startUTF8Offset: bareSuite.positionAfterSkippingLeadingTrivia.utf8Offset,
          endUTF8Offset: bareSuite.endPositionBeforeTrailingTrivia.utf8Offset,
          replacement: ""
        )
      )
    }

    for snapshotSuite in snapshotSuiteAttributes {
      suppressedSnapshotSuiteRenameOffsets.insert(
        snapshotSuite.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset
      )
      suiteAttributeEdits.append(attributeRemovalEdit(for: snapshotSuite))
    }

    if let foldEdit = traitFoldingEdit(into: argumentCarryingSuite, from: snapshotSuiteAttributes) {
      suiteAttributeEdits.append(foldEdit)
    }
  }

  /// Removes an attribute together with its comment-free leading trivia so the deleted
  /// attribute does not leave a blank line behind. Leading trivia containing comments is kept.
  private func attributeRemovalEdit(for attribute: AttributeSyntax) -> TextEdit {
    let leadingTriviaHasComment = attribute.leadingTrivia.contains { piece in
      switch piece {
      case .lineComment, .blockComment, .docLineComment, .docBlockComment:
        return true
      default:
        return false
      }
    }

    let startUTF8Offset = leadingTriviaHasComment
      ? attribute.positionAfterSkippingLeadingTrivia.utf8Offset
      : attribute.position.utf8Offset

    return TextEdit(
      startUTF8Offset: startUTF8Offset,
      endUTF8Offset: attribute.endPositionBeforeTrailingTrivia.utf8Offset,
      replacement: ""
    )
  }

  /// Appends the legacy `@SnapshotSuite` trait arguments to the surviving `@Suite` attribute's
  /// argument list. A plain-string display name in first position is not folded: it never named
  /// the Swift Testing suite (the legacy attribute only fed the snapshot runtime), and its
  /// artifact-naming role survives through the parameterized display-name fallback chain.
  private func traitFoldingEdit(
    into suiteAttribute: AttributeSyntax,
    from snapshotSuiteAttributes: [AttributeSyntax]
  ) -> TextEdit? {
    guard let suiteArguments = suiteAttribute.arguments?.as(LabeledExprListSyntax.self),
          let rightParen = suiteAttribute.rightParen
    else {
      return nil
    }

    var foldedArgumentTexts: [String] = []
    for snapshotSuite in snapshotSuiteAttributes {
      guard let arguments = snapshotSuite.arguments?.as(LabeledExprListSyntax.self) else { continue }
      for (index, argument) in arguments.enumerated() {
        if index == 0, isDisplayNameArgument(argument.expression) { continue }
        foldedArgumentTexts.append(argument.expression.trimmedDescription)
      }
    }

    guard !foldedArgumentTexts.isEmpty else { return nil }

    let insertionOffset = rightParen.positionAfterSkippingLeadingTrivia.utf8Offset
    let separator = suiteArguments.last?.trailingComma == nil ? ", " : " "
    return TextEdit(
      startUTF8Offset: insertionOffset,
      endUTF8Offset: insertionOffset,
      replacement: separator + foldedArgumentTexts.joined(separator: ", ")
    )
  }

  /// A first argument occupying the legacy `displayName` parameter. The legacy overload types
  /// that position as `String`/`String?`, so it is a display name — never a suite trait — whether
  /// it is a string/`nil` literal or a non-literal expression (`Self.suiteName`, `Constants.name`,
  /// `makeName()`). Only leading-dot implicit-member expressions (`.theme(.light)`, `.sizes(...)`)
  /// are traits and may fold into the surviving `@Suite`. Folding a non-literal display name as a
  /// trait produces `@Suite`-variadic type errors, so it must be excluded here.
  private func isDisplayNameArgument(_ expression: ExprSyntax) -> Bool {
    if expression.is(StringLiteralExprSyntax.self) || expression.is(NilLiteralExprSyntax.self) {
      return true
    }
    return !isImplicitMemberTraitExpression(expression)
  }

  /// True when the expression uses leading-dot implicit-member syntax — `.theme`, `.sizes(...)` —
  /// the shape a suite trait takes. An expression with an explicit base (`Self.suiteName`) or a
  /// plain reference/call is not a trait in this position.
  private func isImplicitMemberTraitExpression(_ expression: ExprSyntax) -> Bool {
    if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
      return memberAccess.base == nil
    }
    if let call = expression.as(FunctionCallExprSyntax.self),
       let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self)
    {
      return memberAccess.base == nil
    }
    return false
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let snapshotAttribute = snapshotTestAttribute(in: node.attributes) else {
      return .visitChildren
    }

    let parsed = parse(snapshotAttribute: snapshotAttribute)
    let legacyFunction = LegacyFunction(
      function: node,
      namedLiteral: parsed.namedLiteral,
      namedLiteralIsPlain: parsed.namedLiteralIsPlain,
      suiteDisplayNameLiteral: enclosingSuiteDisplayNameLiteral(for: node),
      snapshotAttributeNameStartUTF8Offset: snapshotAttribute.attributeName.positionAfterSkippingLeadingTrivia.utf8Offset,
      snapshotAttributeNameEndUTF8Offset: snapshotAttribute.attributeName.endPositionBeforeTrailingTrivia.utf8Offset,
      parameterizedArgument: parsed.parameterizedArgument,
      parseIssue: parsed.parseIssue
    )
    legacyFunctions.append(legacyFunction)

    return .visitChildren
  }

  /// Mirrors the legacy macro's suite display-name lookup: the innermost lexical context that
  /// carries a `@SnapshotSuite` attribute wins, and only a plain string literal first argument
  /// counts as its display name — if that attribute has none, the lookup stops (it does not
  /// keep searching outer suites).
  private func enclosingSuiteDisplayNameLiteral(for function: FunctionDeclSyntax) -> String? {
    var current = Syntax(function).parent

    while let node = current {
      if let attributes = declarationAttributes(of: node) {
        let suiteAttribute = attributes
          .compactMap { $0.as(AttributeSyntax.self) }
          .first { attribute in
            attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "SnapshotSuite"
          }

        if let suiteAttribute {
          return plainDisplayNameLiteral(from: suiteAttribute)
        }
      }

      current = node.parent
    }

    return nil
  }

  private func declarationAttributes(of node: Syntax) -> AttributeListSyntax? {
    if let structDecl = node.as(StructDeclSyntax.self) { return structDecl.attributes }
    if let classDecl = node.as(ClassDeclSyntax.self) { return classDecl.attributes }
    if let actorDecl = node.as(ActorDeclSyntax.self) { return actorDecl.attributes }
    if let enumDecl = node.as(EnumDeclSyntax.self) { return enumDecl.attributes }
    if let extensionDecl = node.as(ExtensionDeclSyntax.self) { return extensionDecl.attributes }
    return nil
  }

  private func plainDisplayNameLiteral(from attribute: AttributeSyntax) -> String? {
    guard
      let firstArgument = attribute.arguments?.as(LabeledExprListSyntax.self)?.first,
      let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
      stringLiteral.representedLiteralValue != nil
    else {
      return nil
    }

    return stringLiteral.trimmedDescription
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
      return ParsedSnapshotAttribute(
        namedLiteral: nil,
        namedLiteralIsPlain: false,
        parameterizedArgument: nil,
        parseIssue: nil
      )
    }

    guard let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
      return ParsedSnapshotAttribute(
        namedLiteral: nil,
        namedLiteralIsPlain: false,
        parameterizedArgument: nil,
        parseIssue: AttributeParseIssue(
          code: "unsupported-attribute-arguments",
          message: "Could not parse @SnapshotTest attribute arguments."
        )
      )
    }

    var namedLiteral: String?
    var namedLiteralIsPlain = false
    var parameterizedArgument: ParameterizedSnapshotArgument?
    var parseIssue: AttributeParseIssue?

    for argument in labeledArguments {
      if namedLiteral == nil,
         argument.label == nil,
         let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self)
      {
        namedLiteral = stringLiteral.trimmedDescription
        namedLiteralIsPlain = stringLiteral.representedLiteralValue != nil
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
      namedLiteralIsPlain: namedLiteralIsPlain,
      parameterizedArgument: parameterizedArgument,
      parseIssue: parseIssue
    )
  }
}

private struct LegacyFunction: Hashable {
  let function: FunctionDeclSyntax
  let namedLiteral: String?
  let namedLiteralIsPlain: Bool
  let suiteDisplayNameLiteral: String?
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
  let namedLiteralIsPlain: Bool
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
