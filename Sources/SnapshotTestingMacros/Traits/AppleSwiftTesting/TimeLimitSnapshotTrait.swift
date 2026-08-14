import Foundation
import Testing

@available(iOS 16.0, *)
@available(macOS 13.0, *)
extension Testing.TimeLimitTrait: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "time limit: \(self)"
  }
}

/// Enable `.timeLimit` to compose with snapshot traits on `@Test` and `@Suite`.
@available(iOS 16.0, *)
@available(macOS 13.0, *)
extension Testing.TimeLimitTrait: SnapshotSuiteTrait, SnapshotTestTrait {}
