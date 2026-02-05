import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SnapshotTest {
  var expression: DeclSyntax {
    """
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
  }

  private let snapshotViewGenerator: SnapshotViewGenerator
  private let containerName: TokenSyntax
  private let returnType: TypeSyntax

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
      #warning("TODO: Fail with good error/warnings")
      return nil
    }

    guard
      let suiteName = macroContext.context.lexicalContext.first?.identifierName?.trimmed
    else {
      return nil
    }

    let testDisplayName = makeTestDisplayName(from: snapshotTestFunctionDecl)
    let suiteDisplayName = makeSuiteDisplayName(from: macroContext.context.lexicalContext)
    let testName = snapshotTestFunctionDecl.name.text

    let displayName = testDisplayName ?? suiteDisplayName ?? testName

    self.containerName = makeContainerName(from: snapshotTestFunctionDecl)

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
