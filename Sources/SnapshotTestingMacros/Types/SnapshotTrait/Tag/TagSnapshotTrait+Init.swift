import Foundation
import Testing

/*
 ⚠️ WARNING:

 The below callers currently must match the Swift Testing interfaces defined here:
 https://developer.apple.com/documentation/testing/addingtags

 These are passed along as is to the @Test traits, so need to match.

 TODO: There's potential for creating a mapping type inside of SnapshotMacros to convert one to the other but that's overkill for now.
 */

extension SnapshotTrait where Self == TagSnapshotTrait {
  /**
     Attach tags to the snapshot test..

     More info here: https://developer.apple.com/documentation/testing/addingtags
     */
  public static func tags(
    _ tags: Tag...
  ) -> Self {
    Self(tags: tags)
  }
}
