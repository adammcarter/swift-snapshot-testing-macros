import SwiftSyntax

extension Syntax {
  var identifierName: TokenSyntax? {
    self.as(ActorDeclSyntax.self)?.name
      ?? self.as(ClassDeclSyntax.self)?.name
      ?? self.as(EnumDeclSyntax.self)?.name
      ?? self.as(StructDeclSyntax.self)?.name
  }

  var attributesList: AttributeListSyntax? {
    self.as(ActorDeclSyntax.self)?.attributes
      ?? self.as(ClassDeclSyntax.self)?.attributes
      ?? self.as(EnumDeclSyntax.self)?.attributes
      ?? self.as(StructDeclSyntax.self)?.attributes
  }
}
