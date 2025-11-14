import SwiftSyntax

extension FunctionParameterSyntax {
  var name: TokenSyntax {
    secondName ?? firstName
  }
}
