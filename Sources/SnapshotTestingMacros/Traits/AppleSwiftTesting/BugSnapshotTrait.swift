import Foundation
import Testing

extension Testing.Bug: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "bug: \(self)"
  }
}

extension Testing.Bug: SnapshotSuiteTrait, SnapshotTestTrait {}
