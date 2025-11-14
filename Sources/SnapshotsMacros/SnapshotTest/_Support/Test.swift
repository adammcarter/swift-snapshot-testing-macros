import SnapshotSupport
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SnapshotSuite.TestBlock {

  struct Test {
    var expression: DeclSyntax {
      let baseExpression: DeclSyntax = """
        func \(testFunction.nameExpr)(\(testFunction.parametersExpr)) async throws {
          let generator = \(containerMakeGeneratorExpr)

          try await \(.Namespace.snapshotTestingMacros).assertSnapshot(with: generator)
        }
        """

      var functionDecl = FunctionDeclSyntax(baseExpression)!

      let parsedAttributesListExpr = parsedAttributesListExpr?
        .filter {
          $0.isMainActor || $0.isAvailable
        }

      if parsedAttributesListExpr?.contains(where: \.isMainActor) == false {
        functionDecl.attributes.append(
          .attribute("@\(.AttributeName.mainActor)")
        )
      }

      functionDecl.attributes.append(
        .attribute("@\(.AttributeName.test)(\(testMacro.expr))")
      )

      if let parsedAttributesListExpr {
        functionDecl.attributes.append(
          contentsOf: parsedAttributesListExpr
        )
      }

      functionDecl.attributes = .init {
        functionDecl.attributes.map {
          with($0.trimmed) {
            $0.trailingTrivia = .newline
          }
        }
      }

      return DeclSyntax(functionDecl)
    }

    private let testMacro: TestMacro
    private let testFunction: TestFunction
    private let generatorContainerName: TokenSyntax
    private let parsedAttributesListExpr: AttributeListSyntax?

    private let configurationsExpr: ExprSyntax?
    private let configurationValuesExpr: ExprSyntax?

    private var configurationArrayExpr: ArrayExprSyntax? {
      configurationsExpr?.as(ArrayExprSyntax.self)
    }

    private var containerMakeGeneratorExpr: ExprSyntax {
      "\(generatorContainerName).makeGenerator(\(.Parameters.configuration): \(configurationExpr))"
    }

    private var configurationExpr: ExprSyntax {
      hasConfigurations ? "configuration" : ".none"
    }

    private var hasConfigurations: Bool {
      configurationsExpr != nil || configurationValuesExpr != nil
    }

    init(
      suiteMacroArguments: SnapshotMacroArguments,
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

      let testMacroArguments = makeTestMacroArguments(
        functionDecl: snapshotTestFunctionDecl,
        suiteArguments: suiteMacroArguments
      )

      self.configurationsExpr = testMacroArguments.configurationsExpression
      self.configurationValuesExpr = testMacroArguments.configurationValuesExpression

      self.generatorContainerName = makeContainerName(from: snapshotTestFunctionDecl)

      let configurationExpression =
        testMacroArguments.configurationValuesExpression
        ?? testMacroArguments.configurationsExpression

      self.testMacro = .init(
        traits: makeTestTraitBoxExprs(traitExprs: testMacroArguments.traitExpressions),
        configurationExpression: configurationExpression
      )

      self.testFunction = .init(
        testName: snapshotTestFunctionDecl.name.text,
        configurationExpression: configurationExpression,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      self.parsedAttributesListExpr = snapshotTestFunctionDecl.attributes
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

private func makeTestMacroArguments(
  functionDecl: FunctionDeclSyntax,
  suiteArguments _: SnapshotMacroArguments
) -> SnapshotMacroArguments {
  let node =
    functionDecl
    .firstAttributeNamed(Constants.AttributeName.snapshotTest)
    .flatMap(AttributeSyntax.init)

  return SnapshotMacroArguments(node: node)
}

private func makeTestTraitBoxExprs(traitExprs: [ExprSyntax]?) -> [ExprSyntax] {
  traitExprs?
    .map {
      "\(raw: Constants.Namespace.snapshotTestingMacros).__TestTraitBox(\($0.trimmed)).wrapped" as ExprSyntax
    } ?? []
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
