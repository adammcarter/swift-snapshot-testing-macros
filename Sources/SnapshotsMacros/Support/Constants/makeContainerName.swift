import SwiftSyntax

#warning("TODO: Can we do better than this?")
// Using the uniqueName from context gives two different names inside of each macro (expected) so we'd need to somehow generate one and share it down/up (suite -> test or test -> suite)
func makeContainerName(from functionDecl: FunctionDeclSyntax) -> TokenSyntax {
  TokenSyntax(stringLiteral: "__generator_container_" + functionDecl.name.trimmedDescription)
}
