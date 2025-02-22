import SwiftSyntax

// TODO: Add tests

extension Trivia {
  static var none: Self { [] }
}

extension Trivia {
  var newlinesOnly: Self {
    .init(pieces: filter(\.isNewline))
  }
}
