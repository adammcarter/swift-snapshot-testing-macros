import Foundation
import Testing

extension Tag.List: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "tag: \(self)"
  }
}

/// Enable `.tags` to compose with snapshot traits on `@Test` and `@Suite`.
extension Tag.List: SnapshotSuiteTrait, SnapshotTestTrait {}
