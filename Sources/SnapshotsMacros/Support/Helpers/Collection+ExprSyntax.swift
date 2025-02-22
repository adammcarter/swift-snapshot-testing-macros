import Foundation
import SwiftSyntax

extension Collection where Element == ExprSyntax {
  func containsTraitWithPrefix(_ trait: Constants.Trait) -> Bool {
    contains {
      $0.trimmedDescription.hasPrefix(trait.prefix)
    }
  }
}
