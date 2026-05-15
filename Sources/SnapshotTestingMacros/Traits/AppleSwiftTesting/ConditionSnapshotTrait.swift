import Foundation
import Testing

extension ConditionTrait: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "condition: \(self)"
  }
}

/// Enable `.enabled` and `.disabled` to compose with snapshot traits on `@Test` and `@Suite`.
extension ConditionTrait: SnapshotSuiteTrait, SnapshotTestTrait {}
