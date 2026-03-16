import Foundation
import Testing

@available(iOS 16.0, *)
@available(macOS 13.0, *)
extension Testing.TimeLimitTrait: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "time limit: \(self)"
  }
}

/// Enable `.timeLimit` to be used with `@SnapshotTest` and `@SnapshotSuite`.
@available(iOS 16.0, *)
@available(macOS 13.0, *)
extension Testing.TimeLimitTrait: SnapshotSuiteTrait, SnapshotTestTrait {}
