import SwiftSyntax

extension TypeSyntax {
  #warning("TODO: Add tests ??")
  var isSome: Bool {
    self
      .as(SomeOrAnyTypeSyntax.self)?
      .someOrAnySpecifier
      .tokenKind == .keyword(.some)
  }
}
