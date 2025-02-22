import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// TODO: Make a macro (with attached child macros) like CodableWrappers that creates expressions from members? Sensible defaults - they override
// It would be opt in and each element would have a parameter?
// This might be too convoluted for each use case to have any real utility
struct MacroContext {
  let node: AttributeSyntax
  let declaration: DeclGroupSyntax
  let context: MacroExpansionContext

  init(
    node: AttributeSyntax,
    declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext
  ) {
    self.node = node
    self.declaration = declaration
    self.context = context
  }
}
