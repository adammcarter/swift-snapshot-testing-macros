import Foundation

@MainActor
protocol AssertionRequestGenerating {
  var context: AssertionRequestContext { get }

  func generateRequestsSync() throws -> [any AssertionRequesting]
}

extension AssertionRequestGenerating {
  func generateRequests() async throws -> [any AssertionRequesting] {
    try generateRequestsSync()
  }
}
