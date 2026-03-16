import Foundation
import Testing

/// A protocol describing a trait that can be applied to a snapshot test.
///
/// This protocol serves as a base for both `SnapshotTestTrait` (for individual tests) and `SnapshotSuiteTrait` (for test suites).
/// It requires conformance to `Testing.Trait` and `CustomDebugStringConvertible`.
public protocol SnapshotTrait: Testing.Trait, CustomDebugStringConvertible {}

extension SnapshotTrait {
  /// Used for populating failing test messages with their configuration information.
  public var debugDescription: String {
    "\(Self.self)"
  }
}
