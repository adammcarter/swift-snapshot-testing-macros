import Foundation

@MainActor
protocol AssertionRequestGenerating {
  var context: AssertionRequestContext { get }

  func generateRequests() async throws -> [any AssertionRequesting]
}
