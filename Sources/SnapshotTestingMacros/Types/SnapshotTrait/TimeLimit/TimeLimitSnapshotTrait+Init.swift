import Foundation
import Testing

/*
 ⚠️ WARNING:

 The below callers currently must match the Swift Testing interfaces defined here:
 https://developer.apple.com/documentation/testing/limitingexecutiontime

 These are passed along as is to the @Test traits, so need to match.

 TODO: There's potential for creating a mapping type inside of SnapshotMacros to convert one to the other but that's overkill for now.
 */

@available(iOS 16.0, *) @available(macOS 13.0, *) extension SnapshotTrait where Self == TimeLimitSnapshotTrait {
  /**
     Apply a time limit to a test, if exceeded the test will fail.

     More info here: https://developer.apple.com/documentation/testing/limitingexecutiontime
     */
  public static func timeLimit(
    _ duration: TimeLimitSnapshotTrait.Duration
  ) -> Self {
    Self(duration: duration)
  }
}
