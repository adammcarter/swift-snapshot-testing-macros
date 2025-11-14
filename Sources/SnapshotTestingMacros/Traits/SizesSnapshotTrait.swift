import Foundation
import Testing

public struct SizesSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let sizes: [Size]

  @TaskLocal static var current: [Size] = [
    .init(width: .minimum, height: .minimum)
  ]

  public var debugDescription: String {
    sizes
      .map {
        "\($0.displayName): \($0.debugDescription)"
      }
      .joined(separator: ", ")
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await SizesSnapshotTrait.$current.withValue(sizes) {
      try await function()
    }
  }
}
