import Foundation

// TODO: Add tests

extension String {
  func capitalizingFirst() -> String {
    prefix(1).uppercased() + dropFirst()
  }
}
