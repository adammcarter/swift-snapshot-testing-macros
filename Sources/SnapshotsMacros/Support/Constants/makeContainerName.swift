import SwiftSyntax

// Using the uniqueName from context gives two different names inside of each macro (expected) so
// we'd need to somehow generate one and share it down/up (suite -> test or test -> suite). The
// name is instead derived deterministically from the function so the peer and suite sides agree.
func makeContainerName(from functionDecl: FunctionDeclSyntax) -> TokenSyntax {
  let base = "__generator_container_" + functionDecl.name.generatedIdentifierComponent

  let parameters = functionDecl.signature.parameterClause.parameters

  // Zero-parameter functions cannot be overloaded on their name alone, so they keep the historic
  // bare container name — preserving every existing recorded reference. Parameterised functions,
  // which *can* be overloaded, fold a stable signature hash into the name so two overloads that
  // differ only in their parameters get distinct containers instead of an invalid redeclaration.
  guard parameters.isEmpty == false else {
    return TokenSyntax(stringLiteral: base)
  }

  let signature = parameters
    .map { parameter in
      [
        parameter.firstName.trimmedDescription,
        parameter.secondName?.trimmedDescription ?? "",
        parameter.type.trimmedDescription,
      ]
      .joined(separator: ":")
    }
    .joined(separator: ",")

  return TokenSyntax(stringLiteral: base + "_" + stableSignatureHash(for: signature))
}

private func stableSignatureHash(for string: String) -> String {
  var hash: UInt64 = 14_695_981_039_346_656_037

  for byte in string.utf8 {
    hash ^= UInt64(byte)
    hash &*= 1_099_511_628_211
  }

  let hex = String(hash, radix: 16, uppercase: false)
  let paddedHex = String(repeating: "0", count: max(0, 16 - hex.count)) + hex

  return String(paddedHex.suffix(8))
}
