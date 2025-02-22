import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SnapshotSuite.TestBlock {
  struct Test {
    var expression: DeclSyntax {
      """
      @MainActor
      @Test(\(testMacro.expr))
      func \(testFunction.nameExpr)(\(testFunction.parametersExpr)) async throws {
          let generator = \(raw: Constants.Namespace.snapshotTestingMacros).SnapshotGenerator(
              displayName: \(snapshotGenerator.displayNameExpr),
              traits: \(snapshotGenerator.traitsExpr),
              configuration: \(snapshotGenerator.configurationExpr),
              makeValue: \(snapshotGenerator.makeValueExpr),
              fileID: #fileID,
              filePath: #filePath,
              line: \(snapshotGenerator.lineExpr),
              column: \(snapshotGenerator.columnExpr)
          )

          try await \(raw: Constants.Namespace.snapshotTestingMacros).assertSnapshot(generator: generator)
      }
      """
    }

    private let testMacro: TestMacro
    private let testFunction: TestFunction
    private let snapshotGenerator: SnapshotGenerator

    init(
      suiteName: TokenSyntax,
      suiteDisplayName: String?,
      testDisplayName: String?,
      declaration: Declaration,
      suiteMacroArguments: SnapshotsMacroArguments,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      macroContext: MacroContext
    ) {
      if declaration.isInitializable == false,
        snapshotTestFunctionDecl.isStatic == false
      {
        addNonInstantiableFunctionDiagnostic(
          functionDecl: snapshotTestFunctionDecl,
          context: macroContext.context
        )
      }

      let testMacroArguments = makeArguments(
        functionDecl: snapshotTestFunctionDecl,
        suiteArguments: suiteMacroArguments
      )

      let traitsArrayExpr = makeTraitsArrayExpr(
        suiteTraitExpressions: suiteMacroArguments.traitExpressions,
        testTraitExpressions: testMacroArguments.traitExpressions,
        context: macroContext.context,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      let testMacroTraitExprs = makeTraitsToTransferToTest(traitsArrayExpr: traitsArrayExpr)

      let configurationExpression =
        testMacroArguments.configurationValuesExpression
        ?? testMacroArguments.configurationsExpression

      self.testMacro = .init(
        traits: testMacroTraitExprs,
        configurationExpression: configurationExpression
      )

      let testName = snapshotTestFunctionDecl.name.text

      self.testFunction = .init(
        testName: testName,
        configurationExpression: configurationExpression,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      let displayName = testDisplayName ?? suiteDisplayName ?? testName

      let generatorTraits = makeGeneratorTraits(
        traits: traitsArrayExpr,
        traitsToTransfer: testMacroTraitExprs
      )

      self.snapshotGenerator = .init(
        suiteName: suiteName,
        testName: testName,
        displayName: displayName,
        declaration: declaration,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl,
        testMacroArguments: testMacroArguments,
        traits: generatorTraits,
        macroContext: macroContext
      )
    }
  }
}

private func addNonInstantiableFunctionDiagnostic(functionDecl: FunctionDeclSyntax, context: some MacroExpansionContext) {
  let oldNode = functionDecl
  let newNode = with(oldNode) {
    $0
      .modifiers
      .insert(
        DeclModifierSyntax(name: .keyword(.static)),
        at: $0.modifiers.startIndex
      )
  }

  context.diagnose(
    DiagnosticFactory.generalMessage(
      message: "Cannot create a test for instance functions on types that cannot be initialised.",
      node: functionDecl,
      fixIts: [
        .replace(
          message: FixItWarning.generalMessage("Make function static"),
          oldNode: oldNode,
          newNode: newNode
        )
      ]
    )
  )
}

private func combiningTraits(
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

private func makeDeduped(from traits: [ExprSyntax]) -> [ExprSyntax] {
  var deduped: [ExprSyntax] = []

  for trait in traits {
    if let asTrait = Constants.Trait(expression: trait),
      deduped.containsTraitWithPrefix(asTrait) == false
    {
      deduped.append(trait)
    }
  }

  return deduped
}

private func makeArrayConfigurations(
  configurations: ArrayExprSyntax?,
  configurationGenericType: TupleTypeElementListSyntax
) -> ExprSyntax? {
  guard let configurations else { return nil }

  return ExprSyntax(stringLiteral: "\(configurations) as [\(Constants.TypeName.snapshotConfiguration)<(\(configurationGenericType))>]")
}

private func makeGeneratorTraits(
  traits: ArrayExprSyntax,
  traitsToTransfer: [ExprSyntax]
) -> ArrayExprSyntax {
  let traitsToRemove = Set(traitsToTransfer.map(\.trimmedDescription))

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

private func makeTraitsArrayExpr(
  suiteTraitExpressions: [ExprSyntax]?,
  testTraitExpressions: [ExprSyntax]?,
  context: some MacroExpansionContext,
  snapshotTestFunctionDecl: FunctionDeclSyntax
) -> ArrayExprSyntax {
  let traits = combiningTraits(suiteTraitExpressions, with: testTraitExpressions) ?? suiteTraitExpressions

  var expressions = (traits ?? []).compactMap(\.trimmed)

  diagnoseUnknownTraits(
    traits: traits,
    context: context,
    snapshotTestFunctionDecl: snapshotTestFunctionDecl
  )

  for trait in Constants.Trait.allCases.sorted(by: { $0.rawValue > $1.rawValue }) {
    addTraitIfNotPresent(trait.defaultValue, searchingForTrait: trait, in: &expressions)
  }

  return ArrayExprSyntax {
    expressions
      .map { expression in
        if let mappedValue = Constants.Trait.mappingRawTraitToNewValue(expression.trimmedDescription) {
          ExprSyntax(stringLiteral: mappedValue)
        }
        else {
          expression
        }
      }
      .map {
        ArrayElementSyntax(expression: $0)
      }
  }
}

private func addTraitIfNotPresent(
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

private func diagnoseUnknownTraits(
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

private func makeArguments(
  functionDecl: FunctionDeclSyntax,
  suiteArguments: SnapshotsMacroArguments
) -> SnapshotsMacroArguments {
  if let testAttribute = functionDecl.firstAttributeNamed(Constants.AttributeName.snapshotTest),
    let attribute = AttributeSyntax(testAttribute)
  {
    let testArguments = SnapshotsMacroArguments(node: attribute)

    let combinedTraitExpressions = combiningTraits(
      suiteArguments.traitExpressions,
      with: testArguments.traitExpressions
    )

    return SnapshotsMacroArguments(
      traitExpressions: combinedTraitExpressions,
      configurationsExpression: testArguments.configurationsExpression,
      configurationValuesExpression: testArguments.configurationValuesExpression
    )
  }
  else {
    return suiteArguments
  }
}

private func makeTraitsToTransferToTest(traitsArrayExpr: ArrayExprSyntax) -> [ExprSyntax] {
  let traitsPrefixesToTransfer = Constants.Trait.allCases.filter(\.isSwiftTestingTrait).map(\.prefix)

  return traitsArrayExpr.elements
    .filter { element in
      traitsPrefixesToTransfer.contains(where: element.trimmedDescription.hasPrefix)
    }
    .map(\.trimmed.expression)
}
