import SwiftSyntax

extension AttributeListSyntax {
  func hasAttributeNamed(_ name: String) -> Bool {
    contains { $0.hasAttributeNamed(name) }
  }

  func first(attributeNamed name: String) -> AttributeListSyntax.Element? {
    first { $0.hasAttributeNamed(name) }
  }

  mutating func removingFirstAttributeNamed(_ name: String) {
    if let index = firstIndex(where: { $0.hasAttributeNamed(name) }) {
      remove(at: index)
    }
  }
}

extension AttributeListSyntax.Element {
  static func attributeNamed(_ name: String) -> AttributeListSyntax.Element {
    .init(
      AttributeSyntax(.init(stringLiteral: name))
    )
  }

  func hasAttributeNamed(_ name: String) -> Bool {
    self
      .as(AttributeSyntax.self)?
      .attributeName
      .as(IdentifierTypeSyntax.self)?
      .name
      .trimmed
      .text == name
  }
}
