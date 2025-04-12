import SwiftSyntax

// TODO: Add tests ??

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
        .map { .init(type: $0.type) }
    }
  }
}
