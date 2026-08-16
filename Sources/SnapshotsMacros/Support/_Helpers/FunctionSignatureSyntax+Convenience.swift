import SwiftSyntax

extension FunctionSignatureSyntax {
  var isAsync: Bool {
    effectSpecifiers?.asyncSpecifier != nil
  }

  var isThrows: Bool {
    effectSpecifiers?.throwsClause?.throwsSpecifier != nil
  }

  var parameterClauseAsTuple: TupleTypeElementListSyntax {
    .init {
      parameterClause
        .parameters
        .map { TupleTypeElementSyntax(type: $0.type.strippingParameterOnlyAttributes) }
    }
  }

  /// `inout` and variadic parameters cannot be represented as a plain tuple element in the
  /// `SnapshotConfiguration<(…)>` generic, so they are diagnosed as unsupported rather than
  /// silently producing non-compiling generated code.
  var hasUnsupportedParameterShape: Bool {
    parameterClause.parameters.contains { parameter in
      parameter.ellipsis != nil
        || parameter.type.as(AttributedTypeSyntax.self)?.specifiers.isEmpty == false
    }
  }
}

extension TypeSyntax {
  /// Removes parameter-only type attributes (`@escaping`, `@autoclosure`). These are legal on a
  /// function parameter but illegal in tuple-element / generic-argument position, so they must be
  /// dropped before the type is folded into `SnapshotConfiguration<(…)>`. Type specifiers such as
  /// `inout` are left intact — those are diagnosed as unsupported before the tuple is ever built.
  fileprivate var strippingParameterOnlyAttributes: TypeSyntax {
    guard let attributed = self.as(AttributedTypeSyntax.self) else {
      return self
    }

    guard attributed.specifiers.isEmpty else {
      var stripped = attributed
      stripped.attributes = []
      return TypeSyntax(stripped)
    }

    return attributed.baseType.trimmed
  }
}
