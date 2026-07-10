import SnapshotSupport
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SnapshotTest {
  var expression: DeclSyntax {
    let baseExpression: DeclSyntax = """
      enum \(containerName) {
        @MainActor
        static func makeGenerator(\(.Parameters.configuration): \(snapshotConfigurationType)) -> \(snapshotViewGeneratorType) {
          \(snapshotViewInitialiser)(
            displayName: \(snapshotViewGenerator.displayNameExpr),
            \(.Parameters.configuration): \(.Parameters.configuration),
            makeValue: \(snapshotViewGenerator.makeValueExpr),
            fileID: #fileID,
            filePath: #filePath,
            line: \(snapshotViewGenerator.lineExpr),
            column: \(snapshotViewGenerator.columnExpr)
          )
        }
      }
      """

    /*
     Forward `@available` from the test function onto the container: its `makeValue` calls the
     gated function, so an unannotated container would trip availability checking at the
     deployment target even though the generated test itself is correctly annotated.
     */
    guard
      availabilityAttributes.isEmpty == false,
      var enumDecl = baseExpression.as(EnumDeclSyntax.self)
    else {
      return baseExpression
    }

    enumDecl.attributes = .init {
      availabilityAttributes.map {
        with($0.trimmed) {
          $0.trailingTrivia = .newline
        }
      }
    }

    return DeclSyntax(enumDecl)
  }

  private let snapshotViewGenerator: SnapshotViewGenerator
  private let containerName: TokenSyntax
  private let returnType: TypeSyntax
  private let availabilityAttributes: [AttributeListSyntax.Element]

  private var snapshotConfigurationType: TypeSyntax {
    "\(.TypeName.snapshotConfiguration.namespaced)<\(returnType)>"
  }

  private var snapshotViewGeneratorType: TypeSyntax {
    "any \(.TypeName.snapshotViewGenerating.namespaced)"
  }

  private var snapshotViewInitialiser: TypeSyntax {
    "\(.TypeName.snapshotViewGenerator.namespaced)<\(returnType)>"
  }

  init?(macroContext: SnapshotTestMacroContext) {
    guard
      let snapshotTestFunctionDecl = macroContext.declaration.as(FunctionDeclSyntax.self)
    else {
      macroContext.context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message: "'@SnapshotTest' can only be applied to functions.",
          node: macroContext.node
        )
      )
      return nil
    }

    /*
     Without an enclosing `@SnapshotSuite`, no generated suite ever references the container:
     emitting one would leave a dead — and for non-initialisable enclosing types, non-compiling
     — enum behind while the function silently never runs as a test.
     */
    guard
      let enclosingDecl = macroContext.context.lexicalContext.first,
      enclosingDecl.attributesList?.first(attributeNamed: Constants.AttributeName.snapshotSuite) != nil
    else {
      macroContext.context.diagnose(
        DiagnosticFactory.generalMessage(
          message:
            "'@SnapshotTest' has no effect without an enclosing '@SnapshotSuite' type; no snapshot test will be generated.",
          node: macroContext.node
        )
      )
      return nil
    }

    guard let suiteName = enclosingDecl.identifierName?.trimmed else {
      // e.g. `@SnapshotSuite` on an extension — the suite macro rejects that with an error.
      return nil
    }

    guard snapshotTestFunctionDecl.hasSupportedReturnType else {
      let returnType =
        snapshotTestFunctionDecl.signature.returnClause?.type.trimmedDescription ?? "Void"
      let supportedReturnTypes =
        Constants.Configuration.supportedReturnTypes.sorted().joined(separator: ", ")

      /*
       Warn and skip rather than hard-error. The supported set only recognises the exact spelling
       `some View`, but SwiftUI's runtime generator accepts any `View` — `Text`, `AnyView`,
       `some SwiftUI.View`, view typealiases — all of which previously compiled as a dead-but-valid
       no-op. A view-shaped concrete type or typealias cannot be told apart from a genuinely
       unsupported one at expansion time, so a hard error would break in-progress migrations that
       still build. A warning surfaces the skipped test without breaking the build.
       */
      macroContext.context.diagnose(
        DiagnosticFactory.generalMessage(
          message:
            "'@SnapshotTest' does not support the return type '\(returnType)'; no snapshot test will be generated. Supported return types: \(supportedReturnTypes).",
          node: macroContext.node
        )
      )
      return nil
    }

    if unrepresentableDisplayNameArgument(in: macroContext.node) != nil {
      macroContext.context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message:
            "A '@SnapshotTest' display name must be a simple string literal; interpolation is not supported.",
          node: macroContext.node
        )
      )
      return nil
    }

    /*
     A parameterised function with no configurations expands to a `makeGenerator(configuration:
     .none)` call whose generic argument is the parameter tuple — a guaranteed type mismatch in
     generated code. Reject it here with an actionable message instead.
     */
    let macroArguments = SnapshotMacroArguments(node: macroContext.node)

    if snapshotTestFunctionDecl.signature.parameterClause.parameters.isEmpty == false,
      macroArguments.configurationsExpression == nil,
      macroArguments.configurationValuesExpression == nil
    {
      macroContext.context.diagnose(
        DiagnosticFactory.generalErrorMessage(
          message:
            "A parameterised '@SnapshotTest' function requires a 'configurations:' or 'configurationValues:' argument.",
          node: macroContext.node
        )
      )
      return nil
    }

    let testDisplayName = makeTestDisplayName(from: snapshotTestFunctionDecl)
    let suiteDisplayName = makeSuiteDisplayName(from: macroContext.context.lexicalContext)
    let testName = snapshotTestFunctionDecl.name.text

    let displayName =
      testDisplayName
      ?? suiteDisplayName
      ?? snapshotTestFunctionDecl.name.identifierDisplayName

    self.containerName = makeContainerName(from: snapshotTestFunctionDecl)

    self.availabilityAttributes = snapshotTestFunctionDecl
      .attributes
      .filter(\.isAvailabilityAttribute)

    self.returnType =
      if snapshotTestFunctionDecl.signature.parameterClause.parameters.isEmpty {
        "Void"
      }
      else {
        "(\(raw: snapshotTestFunctionDecl.signature.parameterClauseAsTuple.trimmedDescription))"
      }

    self.snapshotViewGenerator = .init(
      suiteName: suiteName,
      testName: testName,
      displayName: displayName,
      declaration: Declaration(declaration: macroContext.declaration),
      snapshotTestFunctionDecl: snapshotTestFunctionDecl,
      context: macroContext.context
    )
  }
}

private func makeTestDisplayName(from functionDecl: FunctionDeclSyntax) -> String? {
  let attribute = functionDecl
    .attributes
    .first {
      $0.hasAttributeNamed(Constants.AttributeName.snapshotTest)
    }?
    .as(AttributeSyntax.self)

  return makeDisplayName(from: attribute)
}

private func snapshotSuite(from lexicalContext: [Syntax]) -> AttributeSyntax? {
  lexicalContext
    .lazy
    .compactMap {
      $0
        .attributesList?
        .first(attributeNamed: Constants.AttributeName.snapshotSuite)?
        .as(AttributeSyntax.self)
    }
    .first
}

private func snapshotTest(from functionDecl: FunctionDeclSyntax) -> AttributeSyntax? {
  functionDecl
    .attributes
    .first(attributeNamed: Constants.AttributeName.snapshotTest)?
    .as(AttributeSyntax.self)
}

private func makeSuiteDisplayName(from lexicalContext: [Syntax]) -> String? {
  snapshotSuite(from: lexicalContext)
    .flatMap(makeDisplayName)
}

func makeArrayConfigurations(
  configurations: ArrayExprSyntax?,
  configurationGenericType: TupleTypeElementListSyntax
) -> ExprSyntax? {
  guard let configurations else { return nil }

  return "\(raw: configurations) as [\(.TypeName.snapshotConfiguration)<(\(configurationGenericType))>]"
}

extension AttributeListSyntax.Element {
  var isAvailabilityAttribute: Bool {
    if case .attribute(let attribute) = self {
      attribute.attributeName.trimmedDescription.hasPrefix(Constants.AttributeName.available)
    }
    else {
      false
    }
  }
}
