import Foundation
import Testing

extension Tag.List: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "tag: \(self)"
  }
}

extension Tag.List: SnapshotSuiteTrait, SnapshotTestTrait {}
