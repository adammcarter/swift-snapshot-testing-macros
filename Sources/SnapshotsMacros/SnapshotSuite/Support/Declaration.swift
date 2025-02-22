import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct Declaration {
  let isAsync: Bool
  let isThrows: Bool
  let isInitializable: Bool
  let initConfigurationToken: TokenSyntax?

  init(declaration: some DeclGroupSyntax) {
    self.isInitializable = makeIsInitializable(declaration: declaration)
    self.isAsync = makeIsAsync(declaration: declaration)
    self.isThrows = makeIsThrows(declaration: declaration)
    self.initConfigurationToken = makeInitConfigurationToken(declaration: declaration)
  }
}

private func makeIsInitializable(declaration: some DeclGroupSyntax) -> Bool {
  declaration.is(StructDeclSyntax.self)
    || declaration.is(ClassDeclSyntax.self)
    || declaration.is(ActorDeclSyntax.self)
}

private func makeIsAsync(declaration: some DeclGroupSyntax) -> Bool {
  initializer(in: declaration)?.signature.isAsync == true
}

private func makeIsThrows(declaration: some DeclGroupSyntax) -> Bool {
  initializer(in: declaration)?.signature.isThrows == true
}

private func makeInitConfigurationToken(declaration: some DeclGroupSyntax) -> TokenSyntax? {
  initializer(in: declaration)?
    .signature
    .parameterClause
    .parameters
    .first {
      $0.type.as(IdentifierTypeSyntax.self)?.name.identifier?.name == Constants.TypeName.snapshotConfiguration
    }?
    .name
}

private func initializer(in declaration: some DeclGroupSyntax) -> InitializerDeclSyntax? {
  declaration
    .memberBlock
    .members
    .lazy
    .compactMap {
      $0.decl.as(InitializerDeclSyntax.self)
    }
    .first
}
