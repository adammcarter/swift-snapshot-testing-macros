import Foundation

public struct SizesSnapshotTrait: SnapshotTrait {
  let sizes: [Size]

  public var debugDescription: String {
    sizes
      .map {
        "\($0.displayName): \($0.debugDescription)"
      }
      .joined(separator: ", ")
  }
}
