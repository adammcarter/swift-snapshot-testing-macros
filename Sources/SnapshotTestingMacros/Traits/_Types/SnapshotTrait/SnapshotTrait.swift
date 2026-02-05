import Foundation
import Testing

public protocol SnapshotTrait: Testing.Trait, CustomDebugStringConvertible {}

extension SnapshotTrait {
  /// Used for populating failing test messages with their configuration information.
  public var debugDescription: String {
    "\(Self.self)"
  }
}
