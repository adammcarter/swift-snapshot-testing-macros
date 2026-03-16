import Foundation
import Testing

extension Testing.Bug: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "bug: \(self)"
  }
}

/// Enable `.bug` to be used with `@SnapshotTest` and `@SnapshotSuite`.
extension Testing.Bug: SnapshotSuiteTrait, SnapshotTestTrait {}
