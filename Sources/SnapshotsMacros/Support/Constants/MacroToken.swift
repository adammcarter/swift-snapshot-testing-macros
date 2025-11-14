import SwiftSyntaxBuilder

extension SyntaxStringInterpolation {
  mutating func appendInterpolation(_ token: MacroToken) {
    appendInterpolation(raw: token.text)
  }
}

struct MacroToken: Sendable {
  let text: String

  init(_ text: String) {
    self.text = text
  }
}
