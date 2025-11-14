import Foundation
import SnapshotSupport

protocol AccumulatedAssertionRequestGenerating: AssertionRequestGenerating {
  associatedtype Item

  var values: any Collection<Item> { get async throws }

  func accumulateRequests(for value: Item) async throws -> [any AssertionRequesting]
}

extension AccumulatedAssertionRequestGenerating {
  func generateRequests() async throws -> [any AssertionRequesting] {
    var results = [any AssertionRequesting]()

    for value in try await values {
      results.append(contentsOf: try await accumulateRequests(for: value))
    }

    return results
  }
}
