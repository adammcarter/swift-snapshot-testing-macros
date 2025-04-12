import SwiftSyntax

extension TypeSyntax {
  // TODO: Add tests
  var isSome: Bool {
    self
      .as(SomeOrAnyTypeSyntax.self)?
      .someOrAnySpecifier
      .tokenKind == .keyword(.some)
  }
}
