import Foundation

extension Array where Element == Bool {
  public func allSatisfyTrue() -> Bool {
    allSatisfy { $0 == true }
  }
}
