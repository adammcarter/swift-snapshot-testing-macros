import Foundation

extension Array where Element == Bool {
  func allSatisfyTrue() -> Bool {
    allSatisfy { $0 == true }
  }
}
