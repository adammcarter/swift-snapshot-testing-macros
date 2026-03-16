import Foundation
import Testing

extension ConditionTrait: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "condition: \(self)"
  }
}

/// Enable `.enabled` and `.disabled` to be used with `@SnapshotTest` and `@SnapshotSuite`.
extension ConditionTrait: SnapshotSuiteTrait, SnapshotTestTrait {}
