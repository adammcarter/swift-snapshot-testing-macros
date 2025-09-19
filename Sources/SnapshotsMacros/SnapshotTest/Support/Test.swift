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
        try await \(raw: Constants.Namespace.snapshotTestingMacros).assertSnapshot(
          generator: \(raw: generatorContainerName).makeGenerator(configuration: \(configurationExpr))
        )
      }
      """
    }

    private let testMacro: TestMacro
    private let testFunction: TestFunction
    private let generatorContainerName: TokenSyntax

    private var configurationExpr: ExprSyntax? {
      ExprSyntax(stringLiteral: hasConfigurations ? "configuration" : ".none")
    }

    private let configurationsExpr: ExprSyntax?
    private let configurationValuesExpr: ExprSyntax?

    private var configurationArrayExpr: ArrayExprSyntax? {
      configurationsExpr?.as(ArrayExprSyntax.self)
    }

    private var hasConfigurations: Bool {
      configurationsExpr != nil || configurationValuesExpr != nil
    }

    init(
      suiteMacroArguments: SnapshotsMacroArguments,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      macroContext: SnapshotSuiteMacroContext
    ) {
      if Declaration(declaration: macroContext.declaration).isInitializable == false,
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
        snapshotTestFunctionDecl: snapshotTestFunctionDecl,
        addDefaults: false
      )

      let swiftTestingTraits = makeSwiftTestingTraits(traitsArrayExpr: traitsArrayExpr)

      let configurationExpression =
        testMacroArguments.configurationValuesExpression
        ?? testMacroArguments.configurationsExpression

      self.testMacro = .init(
        swiftTestingTraits: swiftTestingTraits,
        configurationExpression: configurationExpression
      )

      let testName = snapshotTestFunctionDecl.name.text

      self.testFunction = .init(
        testName: testName,
        configurationExpression: configurationExpression,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      self.generatorContainerName = makeContainerName(from: snapshotTestFunctionDecl)

      self.configurationsExpr = testMacroArguments.configurationsExpression
      self.configurationValuesExpr = testMacroArguments.configurationValuesExpression
    }
  }
}

private func addNonInstantiableFunctionDiagnostic(
  functionDecl: FunctionDeclSyntax,
  context: some MacroExpansionContext
) {
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

// TODO: Move any non-private stuff out to a shared folder...
func makeTraitsArrayExpr(
  suiteTraitExpressions: [ExprSyntax]?,
  testTraitExpressions: [ExprSyntax]?,
  context: some MacroExpansionContext,
  snapshotTestFunctionDecl: FunctionDeclSyntax,
  addDefaults: Bool
) -> ArrayExprSyntax {
  let combinedTraits = combiningTraits(suiteTraitExpressions, with: testTraitExpressions) ?? suiteTraitExpressions

  var expressions = (combinedTraits ?? []).compactMap(\.trimmed)

  diagnoseUnknownTraits(
    traits: combinedTraits,
    context: context,
    snapshotTestFunctionDecl: snapshotTestFunctionDecl
  )

  if addDefaults {
    for trait in Constants.Trait.allCases.sorted(by: { $0.rawValue > $1.rawValue }) {
      addTraitIfNotPresent(trait.defaultValue, searchingForTrait: trait, in: &expressions)
    }
  }

  return ArrayExprSyntax {
    expressions
      .filter {
        Constants.Trait(expression: $0)?.isConsumedBySnapshotGenerator
          ?? true
      }
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

func makeArguments(
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

func makeSwiftTestingTraits(traitsArrayExpr: ArrayExprSyntax) -> [ExprSyntax] {
  let traitsPrefixesToTransfer = Constants.Trait.allCases.filter(\.isSwiftTestingTrait).map(\.prefix)

  return traitsArrayExpr.elements
    .filter { traitsPrefixesToTransfer.contains(where: $0.trimmedDescription.hasPrefix) }
    .map(\.trimmed.expression)
}
