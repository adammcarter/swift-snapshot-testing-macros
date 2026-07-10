import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct Declaration {
  let isAsync: Bool
  let isThrows: Bool
  let isInitializable: Bool

  init(declaration: some DeclSyntaxProtocol) {
    self.isInitializable = makeIsInitializable(declaration: declaration)
    self.isAsync = makeIsAsync(declaration: declaration)
    self.isThrows = makeIsThrows(declaration: declaration)
  }
}

/*
 The generated code calls `Suite()` with no arguments — the peer macro that bakes the call
 into the generator container cannot see the suite's initialisers (lexical contexts have their
 member lists stripped), so it can never pass anything else. A suite therefore only counts as
 initialisable when that exact zero-argument call compiles:

 - with an explicit initialiser: the first one must be non-failable and require no arguments
   (every parameter defaulted);
 - without one: every stored instance property must already have a value, so the implicit
   (or memberwise) initialiser accepts a zero-argument call.
 */
private func makeIsInitializable(declaration: some DeclSyntaxProtocol) -> Bool {
  guard
    declaration.is(StructDeclSyntax.self)
      || declaration.is(ClassDeclSyntax.self)
      || declaration.is(ActorDeclSyntax.self)
  else {
    return false
  }

  guard let initializerDecl = initializer(in: declaration) else {
    return (declaration as? DeclGroupSyntax)
      .map(storedInstancePropertiesAllHaveValues(in:)) ?? false
  }

  return isCallableWithoutArguments(initializerDecl)
}

private func isCallableWithoutArguments(_ initializerDecl: InitializerDeclSyntax) -> Bool {
  guard initializerDecl.optionalMark == nil else { return false }

  return initializerDecl
    .signature
    .parameterClause
    .parameters
    .allSatisfy { $0.defaultValue != nil }
}

private func storedInstancePropertiesAllHaveValues(in declGroup: DeclGroupSyntax) -> Bool {
  declGroup
    .memberBlock
    .members
    .allSatisfy { member in
      guard
        let variableDecl = member.decl.as(VariableDeclSyntax.self),
        variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) == false
      else {
        return true
      }

      return variableDecl.bindings.allSatisfy { binding in
        guard isStoredBinding(binding) else { return true }

        if binding.initializer != nil { return true }

        // An optional `var` defaults to `nil` in implicit and memberwise initialisers.
        return variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
          && binding.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
      }
    }
}

private func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
  switch binding.accessorBlock?.accessors {
    case .none:
      return true

    case .getter:
      return false

    case .accessors(let accessors):
      // Only observers (`willSet`/`didSet`) keep a binding stored.
      return accessors.allSatisfy { accessor in
        accessor.accessorSpecifier.tokenKind == .keyword(.willSet)
          || accessor.accessorSpecifier.tokenKind == .keyword(.didSet)
      }
  }
}

private func makeIsAsync(declaration: some DeclSyntaxProtocol) -> Bool {
  initializer(in: declaration)?.signature.isAsync == true
}

private func makeIsThrows(declaration: some DeclSyntaxProtocol) -> Bool {
  initializer(in: declaration)?.signature.isThrows == true
}

private func initializer(in declaration: some DeclSyntaxProtocol) -> InitializerDeclSyntax? {
  (declaration as? DeclGroupSyntax)?
    .memberBlock
    .members
    .lazy
    .compactMap { $0.decl.as(InitializerDeclSyntax.self) }
    .first
    ?? declaration.as(InitializerDeclSyntax.self)
}
