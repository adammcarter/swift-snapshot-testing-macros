import Foundation
import Testing

/*
 ⚠️ WARNING:

 The below callers currently must match the Swift Testing interfaces defined here:
 https://developer.apple.com/documentation/testing/enablinganddisabling

 These are passed along as is to the @Test traits, so need to match.

 TODO: There's potential for creating a mapping type inside of SnapshotMacros to convert one to the other but that's overkill for now.
 */

// MARK: Enabled

extension SnapshotTrait where Self == ConditionSnapshotTrait {
  /// Skip a test if the condition evaluates to false.
  public static func enabled(
    if condition: @autoclosure @escaping () throws -> Bool,
    _: Comment? = nil
  ) -> Self {
    Self(condition: condition)
  }

  /// Skip a test if the condition evaluates to false.
  public static func enabled(
    _: Comment? = nil,
    _ condition: @escaping ConditionSnapshotTrait.ConditionHandler
  ) -> Self {
    Self(condition: condition)
  }
}

// MARK: Disabled

extension SnapshotTrait where Self == ConditionSnapshotTrait {
  /// Skip a test  unconditionally.
  public static func disabled(
    _: Comment? = nil
  ) -> Self {
    Self(condition: { false })
  }

  /// Skip a test if the condition evaluates to true.
  public static func disabled(
    if condition: @autoclosure @escaping () throws -> Bool,
    _: Comment? = nil
  ) -> Self {
    Self(condition: { try condition() == false })
  }

  /// Skip a test if the condition evaluates to true.
  public static func disabled(
    _: Comment? = nil,
    _ condition: @escaping () async throws -> Bool
  ) -> Self {
    Self(condition: condition)
  }
}
