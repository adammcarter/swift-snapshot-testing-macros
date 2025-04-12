import SwiftSyntax

extension DeclSyntaxProtocol {
  var attributeList: AttributeListSyntax? {
    self.as(StructDeclSyntax.self)?.attributes
      ?? self.as(EnumDeclSyntax.self)?.attributes
      ?? self.as(ClassDeclSyntax.self)?.attributes
      ?? self.as(ActorDeclSyntax.self)?.attributes
  }
}
