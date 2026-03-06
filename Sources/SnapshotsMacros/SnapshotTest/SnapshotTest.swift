import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SnapshotTest {
  let expression: DeclSyntax

  init?(macroContext: SnapshotTestMacroContext) {
    guard
      let snapshotTestFunctionDecl = macroContext.declaration.as(FunctionDeclSyntax.self)
    else {
      #warning("TODO: Fail with good error/warnings")
      return nil
    }

    let suiteName = macroContext.context.lexicalContext.first?.identifierName?.trimmed

    let testDisplayName = makeTestDisplayName(from: snapshotTestFunctionDecl)
    let suiteDisplayName = makeSuiteDisplayName(from: macroContext.context.lexicalContext)
    let testName = snapshotTestFunctionDecl.name.text

    let displayName = testDisplayName ?? suiteDisplayName ?? testName

    let returnType: TypeSyntax =
      if snapshotTestFunctionDecl.signature.parameterClause.parameters.isEmpty {
        "Void"
      }
      else {
        "(\(raw: snapshotTestFunctionDecl.signature.parameterClauseAsTuple.trimmedDescription))"
      }

    let snapshotViewGenerator = SnapshotViewGenerator(
      testName: testName,
      displayName: displayName,
      declaration: Declaration(declaration: macroContext.declaration),
      snapshotTestFunctionDecl: snapshotTestFunctionDecl,
      context: macroContext.context
    )
    
    // Prepare arguments
    let suiteAttribute = snapshotSuite(from: macroContext.context.lexicalContext)
    let suiteArguments = SnapshotMacroArguments(node: suiteAttribute)
    let testAttribute = snapshotTest(from: snapshotTestFunctionDecl)
    let testArguments = SnapshotMacroArguments(node: testAttribute)

    let suiteTraits = suiteArguments.traitExpressions ?? []
    let testTraits = testArguments.traitExpressions ?? []
    let allTraits = suiteTraits + testTraits
    
    let traitsExprs = makeTestTraitBoxExprs(traitExprs: allTraits)
    
    // Configuration
    let configurationExpr = testArguments.configurationValuesExpression ?? testArguments.configurationsExpression

    var testMacroArguments: [LabeledExprSyntax] = []
    
    // Traits
    for expr in traitsExprs {
        testMacroArguments.append(LabeledExprSyntax(expression: expr, trailingComma: .commaToken()))
    }
    
    // Configuration arguments
    if let configurationExpr {
         let parserString = [
           Constants.Namespace.snapshotTestingMacros,
           Constants.TypeName.snapshotConfigurationParser,
           "parse(\(configurationExpr))",
         ]
         .joined(separator: ".")
         
         testMacroArguments.append(
            LabeledExprSyntax(
                label: .identifier("arguments"), 
                colon: .colonToken(trailingTrivia: .space),
                expression: ExprSyntax(stringLiteral: parserString)
            )
         )
    }
    
    // Fix trailing comma
    if !testMacroArguments.isEmpty {
        var last = testMacroArguments.removeLast()
        last.trailingComma = nil
        testMacroArguments.append(last)
    }

    let traitsList = LabeledExprListSyntax(testMacroArguments)
    
    // Parameters
    let parameters: FunctionParameterListSyntax
    if configurationExpr != nil {
         let configType = snapshotTestFunctionDecl.signature.parameterClauseAsTuple
         parameters = FunctionParameterListSyntax {
            FunctionParameterSyntax(
                firstName: .identifier(Constants.Parameters.configuration),
                colon: .colonToken(trailingTrivia: .space),
                type: TypeSyntax("\(.TypeName.snapshotConfiguration.namespaced)<(\(raw: configType.trimmedDescription))>")
            )
         }
    } else {
        parameters = FunctionParameterListSyntax([])
    }

    // Generator construction
    let configurationArgument: ExprSyntax = configurationExpr != nil ? "configuration" : ".none"
    
    let generatorConstruction: ExprSyntax = """
    \(.TypeName.snapshotViewGenerator.namespaced)<\(returnType)>(
      displayName: \(snapshotViewGenerator.displayNameExpr),
      \(raw: Constants.Parameters.configuration): \(configurationArgument),
      makeValue: \(snapshotViewGenerator.makeValueExpr),
      fileID: #fileID,
      filePath: #filePath,
      line: \(snapshotViewGenerator.lineExpr),
      column: \(snapshotViewGenerator.columnExpr)
    )
    """

    // Function body
    let functionBody: CodeBlockSyntax = CodeBlockSyntax {
      "let generator = \(generatorConstruction)"
      "try await \(.Namespace.snapshotTestingMacros).assertSnapshot(with: generator)"
    }
    
    // Function attributes
    var attributes: [AttributeListSyntax.Element] = snapshotTestFunctionDecl.attributes.filter { $0.isMainActor || $0.isAvailable }
    if !attributes.contains(where: \.isMainActor) {
        attributes.append(.attribute("@\(.AttributeName.mainActor)"))
    }
    attributes.append(.attribute("@\(.AttributeName.test)(\(traitsList))"))

    // Build function
    let functionDecl = FunctionDeclSyntax(
        attributes: AttributeListSyntax(attributes),
        modifiers: DeclModifierListSyntax([]), // Could add static if original is static?
        funcKeyword: .keyword(.func),
        name: .identifier("\(testName)_snapshotTest"),
        signature: FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(parameters: parameters),
            effectSpecifiers: FunctionEffectSpecifiersSyntax(asyncSpecifier: .keyword(.async), throwsSpecifier: .keyword(.throws))
        ),
        body: functionBody
    )
    
    self.expression = DeclSyntax(functionDecl)
  }
}

private func makeTestTraitBoxExprs(traitExprs: [ExprSyntax]) -> [ExprSyntax] {
  traitExprs.map {
    "\(raw: Constants.Namespace.snapshotTestingMacros).__TestTraitBox(\($0.trimmed)).wrapped" as ExprSyntax
  }
}

extension AttributeListSyntax.Element {
  fileprivate var isMainActor: Bool {
    hasPrefix(Constants.AttributeName.mainActor)
  }

  fileprivate var isAvailable: Bool {
    hasPrefix(Constants.AttributeName.available)
  }

  fileprivate func hasPrefix(_ name: String) -> Bool {
    if case .attribute(let attribute) = self {
      attribute.attributeName.trimmedDescription.hasPrefix(name)
    }
    else {
      false
    }
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

private func makeDisplayName(from attribute: AttributeSyntax?) -> String? {
  attribute?
    .arguments?
    .as(LabeledExprListSyntax.self)?
    .first?
    .expression
    .as(StringLiteralExprSyntax.self)?
    .representedLiteralValue
}

func makeArrayConfigurations(
  configurations: ArrayExprSyntax?,
  configurationGenericType: TupleTypeElementListSyntax
) -> ExprSyntax? {
  guard let configurations else { return nil }

  return "\(raw: configurations) as [\(.TypeName.snapshotConfiguration)<(\(configurationGenericType))>]"
}
