import Foundation
import Testing

/*
 ⚠️ WARNING:

 The below callers currently must match the Swift Testing interfaces defined here:
 https://developer.apple.com/documentation/testing/bugidentifiers

 These are passed along as is to the @Test traits, so need to match.

 TODO: There's potential for creating a mapping type inside of SnapshotMacros to convert one to the other but that's overkill for now.
 */

extension SnapshotTrait where Self == BugSnapshotTrait {
  /**
   Apply a known bug to the test.

   More info here: https://developer.apple.com/documentation/testing/bugidentifiers
   */
  public static func bug(
    _ url: String,
    _ title: Comment? = nil
  ) -> Self {
    Self(comment: title, url: url)
  }

  /**
   Apply a known bug to the test.

   More info here: https://developer.apple.com/documentation/testing/bugidentifiers
   */
  public static func bug(
    _ url: String? = nil,
    id: String,
    _ title: Comment? = nil
  ) -> Self {
    Self(comment: title, id: id, url: url)
  }

  /**
   Apply a known bug to the test.

   More info here: https://developer.apple.com/documentation/testing/bugidentifiers
   */
  public static func bug(
    _ url: String? = nil,
    id: some Numeric,
    _ title: Comment? = nil
  ) -> Self {
    Self(comment: title, id: "\(id)", url: url)
  }
}
