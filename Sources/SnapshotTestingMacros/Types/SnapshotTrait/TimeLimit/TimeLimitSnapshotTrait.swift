import Foundation
import Testing

// Swift Testing limits this type to macOS 13 minimum, so we'll do the same.
@available(iOS 16.0, *) @available(macOS 13.0, *) public struct TimeLimitSnapshotTrait: SnapshotTrait {
  public typealias Duration = TimeLimitTrait.Duration
  public typealias Comment = Testing.Comment

  let duration: Duration

  public var debugDescription: String { "time limit: \(duration)" }

  init(duration: Duration) {
    self.duration = duration
  }
}
