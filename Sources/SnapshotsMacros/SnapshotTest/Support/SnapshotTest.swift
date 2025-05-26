import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SnapshotTest {
  var expression: DeclSyntax {
    """
    enum \(containerName) {
      @MainActor
      static func makeGenerator(configuration: SnapshotConfiguration<\(returnType)>) -> \(raw: Constants.Namespace.snapshotTestingMacros).SnapshotGenerator<\(returnType)> {
        \(raw: Constants.Namespace.snapshotTestingMacros).SnapshotGenerator(
          displayName: \(snapshotGenerator.displayNameExpr),
          traits: \(snapshotGenerator.traitsExpr),
          configuration: configuration,
          makeValue: \(snapshotGenerator.makeValueExpr),
          fileID: #fileID,
          filePath: #filePath,
          line: \(snapshotGenerator.lineExpr),
          column: \(snapshotGenerator.columnExpr)
        )
      }
    }
    """
  }

  private let snapshotGenerator: SnapshotGenerator
  private let containerName: TokenSyntax
  private let returnType: TypeSyntax

  init?(macroContext: SnapshotTestMacroContext) {
    guard
      let snapshotTestFunctionDecl = macroContext.declaration.as(FunctionDeclSyntax.self)
    else {
      // TODO: Fail with good error/warnings
      return nil
    }

    guard
      let suiteName = macroContext.context.lexicalContext.first?.identifierName?.trimmed
    else {
      return nil
    }

    guard
      let suiteNode = snapshotSuite(from: macroContext.context.lexicalContext)
    else {
      return nil
    }

    guard
      let testNode = snapshotTest(from: snapshotTestFunctionDecl)
    else {
      return nil
    }

    let suiteDisplayName = makeSuiteDisplayName(
      from: macroContext.context.lexicalContext
    )

    let suiteMacroArguments = SnapshotsMacroArguments(node: suiteNode)
    let testMacroArguments = SnapshotsMacroArguments(node: testNode)

    let testDisplayName = makeTestDisplayName(from: snapshotTestFunctionDecl)

    let containerName = makeContainerName(from: snapshotTestFunctionDecl)

    let declaration = Declaration(declaration: macroContext.declaration)

    // Old combination - but we probably don't want this ...
//    let combinedMacroArguments = makeArguments(
//      functionDecl: snapshotTestFunctionDecl,
//      suiteArguments: suiteMacroArguments
//    )

    let traitsArrayExpr = makeTraitsArrayExpr(
      suiteTraitExpressions: suiteMacroArguments.traitExpressions,
      testTraitExpressions: testMacroArguments.traitExpressions,
      context: macroContext.context,
      snapshotTestFunctionDecl: snapshotTestFunctionDecl,
      addDefaults: false
    )

    let swiftTestingTraits = makeSwiftTestingTraits(traitsArrayExpr: traitsArrayExpr)

    let testName = snapshotTestFunctionDecl.name.text

    let displayName = testDisplayName ?? suiteDisplayName ?? testName

    self.containerName = containerName
    self.returnType =
      if snapshotTestFunctionDecl.signature.parameterClause.parameters.isEmpty {
        .init(stringLiteral: "Void")
      }
      else {
        .init(stringLiteral: "(\(snapshotTestFunctionDecl.signature.parameterClauseAsTuple.trimmedDescription))")
      }

    let generatorTraits = makeGeneratorTraits(
      traits: traitsArrayExpr,
      swiftTestingTraits: swiftTestingTraits
    )

    self.snapshotGenerator = .init(
      suiteName: suiteName,
      testName: testName,
      displayName: displayName,
      declaration: declaration,
      snapshotTestFunctionDecl: snapshotTestFunctionDecl,
      traits: generatorTraits,
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
    .flatMap { makeDisplayName(from: $0) }
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

func combiningTraits(
  _ traits: [ExprSyntax]?,
  with otherTraits: [ExprSyntax]?
) -> [ExprSyntax]? {
  if let otherTraits, let traits {
    makeDeduped(from: (otherTraits + traits))
  }
  else {
    otherTraits ?? traits
  }
}

func makeDeduped(from traitExpressions: [ExprSyntax]) -> [ExprSyntax] {
  var deduped: [ExprSyntax] = []

  for traitExpression in traitExpressions {
    if
      let asTrait = Constants.Trait(expression: traitExpression),
      deduped.containsTraitWithPrefix(asTrait) == false
    {
      deduped.append(traitExpression)
    } else if Constants.Trait.isUnknown(traitExpression) {
      deduped.append(traitExpression)
    }
  }

  return deduped
}

func makeArrayConfigurations(
  configurations: ArrayExprSyntax?,
  configurationGenericType: TupleTypeElementListSyntax
) -> ExprSyntax? {
  guard let configurations else { return nil }

  return ExprSyntax(stringLiteral: "\(configurations) as [\(Constants.TypeName.snapshotConfiguration)<(\(configurationGenericType))>]")
}

func makeGeneratorTraits(
  traits: ArrayExprSyntax,
  swiftTestingTraits: [ExprSyntax]
) -> ArrayExprSyntax {
  let traitsToRemove = Set(swiftTestingTraits.map(\.trimmedDescription))

  return ArrayExprSyntax {
    traits.elements
      .filter {
        traitsToRemove.contains($0.expression.trimmedDescription) == false
      }
      .map {
        ArrayElementSyntax(expression: $0.expression)
      }
  }
}

func addTraitIfNotPresent(
  _ trait: String?,
  searchingForTrait traitToFind: Constants.Trait,
  in expressions: inout [ExprSyntax]
) {
  guard
    let trait,
    expressions.containsTraitWithPrefix(traitToFind) == false
  else { return }

  expressions.append(ExprSyntax(stringLiteral: trait))
}

func diagnoseUnknownTraits(
  traits: [ExprSyntax]?,
  context: some MacroExpansionContext,
  snapshotTestFunctionDecl: FunctionDeclSyntax
) {
  guard let traits else { return }

  let unknownTraits =
    traits
    .filter { traitExpr in
      guard let trait = Constants.Trait(expression: traitExpr) else {
        return false
      }

      return Constants.Trait.allCases.contains(where: { $0.prefix == trait.prefix }) == false
    }
    .map(\.trimmedDescription)

  guard unknownTraits.isEmpty == false else { return }

  let description: String

  if #available(macOS 12.0, *), #available(iOS 15.0, *) {
    description = unknownTraits.formatted(.list(type: .and))
  }
  else {
    description = unknownTraits.joined(separator: ", ")
  }

  context.diagnose(
    DiagnosticFactory.generalMessage(
      message: "Unknown traits: \(description). If it's a new trait, add it to `Constants.Trait` enum.",
      node: snapshotTestFunctionDecl
    )
  )
}
