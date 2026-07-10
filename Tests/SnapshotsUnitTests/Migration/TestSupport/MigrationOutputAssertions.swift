import SwiftParser
import Testing

/// Asserts that rewriter output is syntactically valid Swift, guarding against rewrites that
/// splice together non-compiling code (corrupted initializers, dangling attribute arguments).
func expectParsesCleanly(
  _ source: String,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  let tree = Parser.parse(source: source)
  #expect(
    !tree.hasError,
    "Rewriter output does not parse cleanly:\n\(source)",
    sourceLocation: sourceLocation
  )
}
