import Foundation
import SnapshotSupport

protocol AccumulatedAssertionRequestGenerating: AssertionRequestGenerating {
  associatedtype Item

  var values: any Collection<Item> { get throws }

  func accumulateRequests(for value: Item) throws -> [any AssertionRequesting]
}

extension AccumulatedAssertionRequestGenerating {
  func generateRequestsSync() throws -> [any AssertionRequesting] {
    var results = [any AssertionRequesting]()

    for value in try values {
      results.append(contentsOf: try accumulateRequests(for: value))
    }

    return results
  }
}
