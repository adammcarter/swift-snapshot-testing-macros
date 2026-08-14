import Foundation
import Testing

extension Testing.Bug: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "bug: \(self)"
  }
}

/// Enable `.bug` to compose with snapshot traits on `@Test` and `@Suite`.
extension Testing.Bug: SnapshotSuiteTrait, SnapshotTestTrait {}
