#if os(macOS)
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@testable import SnapshotsMacros

struct SequenceInterspersingTests {

  @Test(
    arguments: [
      (
        [
          "1",
          "2",
          "3",
        ] as [ExprSyntax],
        Trivia.newlines(1),
        3,
        Trivia.none,
        Trivia.newlines(1),
        Trivia.newlines(1)
      )
    ]
  )
  func interspersing(
    input: [ExprSyntax],
    leadingTrivia: Trivia,
    expectedCount: Int,
    firstTrivia: Trivia,
    secondTrivia: Trivia,
    thirdTrivia: Trivia
  ) {
    let interspersed = input.interspersing(leadingTrivia: leadingTrivia)

    #expect(interspersed.count == expectedCount)
    #expect(interspersed[0].leadingTrivia == firstTrivia)
    #expect(interspersed[1].leadingTrivia == secondTrivia)
    #expect(interspersed[2].leadingTrivia == thirdTrivia)
  }

  @Test
  func interspersingEmpty() {
    let items: [ExprSyntax] = []
    let interspersed = items.interspersing(leadingTrivia: .newlines(1))

    #expect(interspersed.isEmpty)
  }

  @Test
  func interspersingSingle() {
    let items: [ExprSyntax] = ["1"]
    let interspersed = items.interspersing(leadingTrivia: .newlines(1))

    #expect(interspersed.count == 1)
    #expect(interspersed[0].leadingTrivia == .none)
  }
}
#endif
