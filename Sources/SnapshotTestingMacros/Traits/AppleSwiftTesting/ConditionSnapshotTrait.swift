import Foundation
import Testing

extension ConditionTrait: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "condition: \(self)"
  }
}

extension ConditionTrait: SnapshotSuiteTrait, SnapshotTestTrait {}
