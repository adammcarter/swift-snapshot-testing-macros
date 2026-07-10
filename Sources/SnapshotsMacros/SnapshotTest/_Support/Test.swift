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

    init?(
      suiteMacroArguments: SnapshotMacroArguments,
      snapshotTestFunctionDecl: FunctionDeclSyntax,
      macroContext: SnapshotSuiteMacroContext
    ) {
      let suiteDeclaration = Declaration(declaration: macroContext.declaration)

      /*
       Generating `Suite().test()` for a suite that cannot be initialised with the arguments
       the macro passes is a guaranteed compile error inside generated code. Diagnose it as an
       error and generate nothing for this function.
       */
      if suiteDeclaration.isInitializable == false,
        snapshotTestFunctionDecl.isStatic == false
      {
        addNonInstantiableFunctionDiagnostic(
          functionDecl: snapshotTestFunctionDecl,
          context: macroContext.context
        )

        return nil
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
      let functionNeedsAsync =
        suiteDeclaration.isAsync
        && snapshotTestFunctionDecl.isAsync == false
        && snapshotTestFunctionDecl.isStatic == false

      let functionNeedsThrows =
        suiteDeclaration.isThrows
        && snapshotTestFunctionDecl.isThrows == false
        && snapshotTestFunctionDecl.isStatic == false

      if functionNeedsAsync {
        addAsyncInitialiserDiagnostic(
          functionDecl: snapshotTestFunctionDecl,
          alsoAddThrows: functionNeedsThrows,
          context: macroContext.context
        )
      }

      /*
       The peer macro bakes `Suite().function()` but only emits `try` when the *function*
       throws. A non-throwing instance function on a suite with a throwing initialiser therefore
       generates a call to the throwing initialiser with no `try` — "call can throw but is not
       marked with 'try'" in generated code. Diagnose it here, where the suite's initialiser is
       visible, mirroring the async-init guard. (A throwing function's `try` covers the
       initialiser call too.)
      */
      if functionNeedsThrows {
        addThrowingInitialiserDiagnostic(
          functionDecl: snapshotTestFunctionDecl,
          alsoAddAsync: functionNeedsAsync,
          context: macroContext.context
        )
      }

      // `inout`/variadic parameters are diagnosed as unsupported by the peer macro; skip here so
      // the suite does not reference a container the peer never generated.
      if snapshotTestFunctionDecl.signature.hasUnsupportedParameterShape {
        return nil
      }

      let testMacroArguments = makeTestMacroArguments(
        functionDecl: snapshotTestFunctionDecl,
        suiteArguments: suiteMacroArguments
      )

      /*
       A parameterised function without configurations would call `makeGenerator(configuration:
       .none)` where the container expects `SnapshotConfiguration<(Params)>` — a type mismatch
       in generated code. The peer macro diagnoses this as an error; generate nothing here so
       the only compiler output is that diagnostic.
       */
      if snapshotTestFunctionDecl.signature.parameterClause.parameters.isEmpty == false,
        testMacroArguments.configurationsExpression == nil,
        testMacroArguments.configurationValuesExpression == nil
      {
        return nil
      }

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
    /*
     The whitespace (newline + indent) separating the attributes from `func` lives on the
     leading trivia of whichever token comes first — the first modifier if one exists,
     otherwise `func`. Hand that trivia to the inserted `static` and leave a single space in the
     vacated slot; otherwise the trivia-less modifier fuses onto the attribute as the unknown
     attribute `@SnapshotTeststatic`.
     */
    let leadingTrivia: Trivia
    if let firstModifier = $0.modifiers.first {
      leadingTrivia = firstModifier.leadingTrivia
      $0.modifiers[$0.modifiers.startIndex].leadingTrivia = .space
    }
    else {
      leadingTrivia = $0.funcKeyword.leadingTrivia
      $0.funcKeyword.leadingTrivia = .space
    }

    $0
      .modifiers
      .insert(
        DeclModifierSyntax(name: .keyword(.static, leadingTrivia: leadingTrivia)),
        at: $0.modifiers.startIndex
      )
  }

  context.diagnose(
    DiagnosticFactory.generalErrorMessage(
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
  alsoAddThrows: Bool,
  context: some MacroExpansionContext
) {
  context.diagnose(
    DiagnosticFactory.generalErrorMessage(
      message:
        "Cannot create a test for non-async instance functions on a suite with an 'async' initialiser. Make the function 'async' so the generated code can await the initialiser.",
      node: functionDecl,
      fixIts: [
        .replace(
          message: FixItWarning.generalMessage("Make function async"),
          oldNode: functionDecl,
          newNode: withAddedEffectSpecifiers(
            to: functionDecl,
            async: true,
            throws: alsoAddThrows
          )
        )
      ]
    )
  )
}

private func addThrowingInitialiserDiagnostic(
  functionDecl: FunctionDeclSyntax,
  alsoAddAsync: Bool,
  context: some MacroExpansionContext
) {
  context.diagnose(
    DiagnosticFactory.generalErrorMessage(
      message:
        "Cannot create a test for non-throwing instance functions on a suite with a 'throws' initialiser. Make the function 'throws' so the generated code can 'try' the initialiser.",
      node: functionDecl,
      fixIts: [
        .replace(
          message: FixItWarning.generalMessage("Make function throws"),
          oldNode: functionDecl,
          newNode: withAddedEffectSpecifiers(
            to: functionDecl,
            async: alsoAddAsync,
            throws: true
          )
        )
      ]
    )
  )
}

/// Adds the requested effect specifiers to a function's signature so the fix-it always yields a
/// function whose specifiers match the suite initialiser the generated code calls — for an
/// `async throws` initialiser that means adding both `async` and `throws` in one fix so the peer
/// emits `try await`.
private func withAddedEffectSpecifiers(
  to functionDecl: FunctionDeclSyntax,
  async addAsync: Bool,
  throws addThrows: Bool
) -> FunctionDeclSyntax {
  with(functionDecl) {
    $0.signature.effectSpecifiers = with(
      $0.signature.effectSpecifiers ?? FunctionEffectSpecifiersSyntax()
    ) {
      if addAsync {
        $0.asyncSpecifier = .keyword(.async, trailingTrivia: .space)
      }

      if addThrows {
        $0.throwsClause = ThrowsClauseSyntax(
          throwsSpecifier: .keyword(.throws, trailingTrivia: .space)
        )
      }
    }
  }
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
