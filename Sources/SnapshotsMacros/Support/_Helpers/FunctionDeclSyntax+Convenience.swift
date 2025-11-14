import SwiftSyntax

#warning("TODO: Add tests ??")

extension FunctionDeclSyntax {
  var isAsync: Bool {
    signature.isAsync
  }

  var isThrows: Bool {
    signature.isThrows
  }

  var isStatic: Bool {
    modifiers.contains { $0.name.tokenKind == .keyword(.static) }
  }

  var isSupportedForSnapshots: Bool {
    hasAttributeNamed(Constants.AttributeName.snapshotTest) && hasSupportedReturnType
  }

  func hasReturnType(_ type: String) -> Bool {
    signature.returnClause?.type.trimmedDescription == TypeSyntax(stringLiteral: type).trimmedDescription
  }

  var hasSupportedReturnType: Bool {
    Constants.Configuration.supportedReturnTypes.contains(where: hasReturnType)
  }

  func hasAttributeNamed(_ name: String) -> Bool {
    attributes.contains { $0.hasAttributeNamed(name) }
  }

  func firstAttributeNamed(_ name: String) -> AttributeListSyntax.Element? {
    attributes.first { $0.hasAttributeNamed(name) }
  }
}
