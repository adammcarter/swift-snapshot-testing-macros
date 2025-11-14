import Foundation
import Testing

public protocol SnapshotTestScoping: Testing.Trait {
  func provideScope(
    performing function: () async throws -> Void
  ) async throws
}
