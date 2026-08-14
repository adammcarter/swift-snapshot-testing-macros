import Foundation
import Testing

/// A trait that configures the sizes for snapshot tests.
///
/// Use this trait to specify the dimensions for your snapshots. You can provide explicit sizes,
/// use predefined device sizes, or rely on minimum sizing.
///
/// Example:
/// ```swift
/// @Suite
/// struct MySnapshotSuite {
///   @Test(.sizes(devices: .iPhoneX))
///   func myView() {
///     #expectSnapshot(MyView())
///   }
/// }
/// ```
public struct SizesSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let sizes: [Size]

  @TaskLocal
  static var current: [Size] = [
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
