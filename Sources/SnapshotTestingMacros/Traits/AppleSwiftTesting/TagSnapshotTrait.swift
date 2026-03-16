import Foundation
import Testing

extension Tag.List: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "tag: \(self)"
  }
}

/// Enable `.tags` to be used with `@SnapshotTest` and `@SnapshotSuite`.
extension Tag.List: SnapshotSuiteTrait, SnapshotTestTrait {}
