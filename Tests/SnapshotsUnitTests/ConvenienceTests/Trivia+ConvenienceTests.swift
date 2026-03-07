#if os(macOS)
import SwiftSyntax
import Testing

@testable import SnapshotsMacros

struct TriviaConvenienceTests {
  @Test
  func none() {

    #expect(Trivia.none == [])
  }

  @Test
  func newlinesOnly() {
    let trivia: Trivia = .newlines(2) + .spaces(4) + .newlines(1) + .tabs(1)

    #expect(trivia.newlinesOnly == .newlines(2) + .newlines(1))
  }
}
#endif
