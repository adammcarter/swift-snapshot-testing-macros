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
    private let displayNameOverride: String?

    private let configurationsExpr: ExprSyntax?
    private let configurationValuesExpr: ExprSyntax?

    private var configurationArrayExpr: ArrayExprSyntax? {
      configurationsExpr?.as(ArrayExprSyntax.self)
    }

    private var containerMakeGeneratorExpr: ExprSyntax {
      let makeGeneratorExpr: ExprSyntax =
        "\(generatorContainerName).makeGenerator(\(.Parameters.configuration): \(configurationExpr))"

      guard let displayNameOverride else {
        return makeGeneratorExpr
      }

      return "\(raw: Constants.Namespace.snapshotTestingMacros).__overridingDisplayName(of: \(makeGeneratorExpr), with: \(literal: displayNameOverride))"
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
      let suiteDeclaration = Declaration(declaration: macroContext.declaration)

      if suiteDeclaration.isInitializable == false,
        snapshotTestFunctionDecl.isStatic == false
      {
        addNonInstantiableFunctionDiagnostic(
          functionDecl: snapshotTestFunctionDecl,
          context: macroContext.context
        )
      }

      /*
       The peer macro bakes `Suite().function()` into the generator container, but it cannot
       see the suite's initialiser (lexical contexts have their member lists stripped), so it
       only emits `await` when the *function* is async. A non-async instance function on a
       suite with an async initialiser therefore generates a call to the async initialiser
       with no `await` — a guaranteed compile error in generated code. Diagnose it here, where
       the full suite declaration is visible, so the user gets an actionable error instead of
       a cryptic one inside macro-generated code. (An async function is fine: its `await`
       covers the initialiser call too.)
      */
      if suiteDeclaration.isAsync,
        snapshotTestFunctionDecl.isAsync == false,
        snapshotTestFunctionDecl.isStatic == false
      {
        addAsyncInitialiserDiagnostic(
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
        testName: snapshotTestFunctionDecl.name,
        configurationExpression: configurationExpression,
        snapshotTestFunctionDecl: snapshotTestFunctionDecl
      )

      self.parsedAttributesListExpr = snapshotTestFunctionDecl.attributes

      self.displayNameOverride = makeDisplayNameOverride(
        snapshotTestFunctionDecl: snapshotTestFunctionDecl,
        macroContext: macroContext
      )
    }
  }
}

/// The peer macro bakes `testDisplayName ?? suiteDisplayName ?? functionName` into each
/// generator container, so every test that falls back to the suite display name resolves the
/// same reference artifacts — persistent false failures for multi-test named suites, or silent
/// overwrites in record mode. The peer macro cannot see its siblings (lexical contexts have
/// their member lists stripped), so the suite expansion — which can — disambiguates the
/// fallback per test as `<suite name>/<function name>`.
///
/// The override only fires when two or more tests actually share the suite-name fallback:
/// a single fallback test keeps producing exactly the artifact names main produced, so
/// existing recorded references stay valid.
private func makeDisplayNameOverride(
  snapshotTestFunctionDecl: FunctionDeclSyntax,
  macroContext: SnapshotSuiteMacroContext
) -> String? {
  // A test's own display name always wins and never collides through the suite fallback.
  guard testDisplayName(for: snapshotTestFunctionDecl) == nil else {
    return nil
  }

  guard let suiteDisplayName = makeDisplayName(from: macroContext.node) else {
    return nil
  }

  guard suiteFallbackTestCount(in: macroContext.declaration.memberBlock.members) >= 2 else {
    return nil
  }

  let functionDisplayName = snapshotTestFunctionDecl.name.identifierDisplayName

  return [suiteDisplayName, functionDisplayName]
    .filter { $0.isEmpty == false }
    .joined(separator: "/")
}

private func testDisplayName(for functionDecl: FunctionDeclSyntax) -> String? {
  let attribute = functionDecl
    .firstAttributeNamed(Constants.AttributeName.snapshotTest)
    .flatMap(AttributeSyntax.init)

  return makeDisplayName(from: attribute)
}

/// Counts the tests that would fall back to the suite display name. `#if` blocks contribute
/// their largest clause: at most one clause compiles at a time, so that is the highest number
/// of fallback tests that can coexist.
private func suiteFallbackTestCount(in members: MemberBlockItemListSyntax) -> Int {
  members.reduce(into: 0) { count, member in
    if let function = member.decl.as(FunctionDeclSyntax.self) {
      if function.isSupportedForSnapshots, testDisplayName(for: function) == nil {
        count += 1
      }
    }
    else if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
      count +=
        ifConfig
        .clauses
        .compactMap { $0.elements?.as(MemberBlockItemListSyntax.self) }
        .map(suiteFallbackTestCount(in:))
        .max() ?? 0
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

private func addAsyncInitialiserDiagnostic(
  functionDecl: FunctionDeclSyntax,
  context: some MacroExpansionContext
) {
  let oldNode = functionDecl
  let newNode = with(oldNode) {
    $0.signature.effectSpecifiers = with(
      $0.signature.effectSpecifiers ?? FunctionEffectSpecifiersSyntax()
    ) {
      $0.asyncSpecifier = .keyword(.async, trailingTrivia: .space)
    }
  }

  context.diagnose(
    DiagnosticFactory.generalErrorMessage(
      message:
        "Cannot create a test for non-async instance functions on a suite with an 'async' initialiser. Make the function 'async' so the generated code can await the initialiser.",
      node: functionDecl,
      fixIts: [
        .replace(
          message: FixItWarning.generalMessage("Make function async"),
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
