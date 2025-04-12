import Foundation
import SwiftSyntax

// TODO: Add tests

extension Sequence {
  func interspersing<T: SyntaxProtocol>(leadingTrivia: Trivia) -> [T] where Element == T {
    enumerated()
      .map { (index, expression) in
        with(expression) {
          $0.leadingTrivia = index > 0 ? leadingTrivia : .none
        }
      }
  }
}
