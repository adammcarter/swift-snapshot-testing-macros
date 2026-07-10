import Foundation

@MainActor
public protocol SnapshotViewGenerating {
  associatedtype ConfigurationValue: Sendable

  var displayName: String { get }
  var configuration: SnapshotConfiguration<ConfigurationValue> { get }
  var makeViewController: @MainActor (ConfigurationValue) throws -> SnapshotViewController { get }
  /// Non-nil when the snapshot value can only be produced asynchronously. The assertion entry
  /// point awaits it once, then runs the synchronous pipeline against the resolved value.
  var makeViewControllerAsync: (@MainActor (ConfigurationValue) async throws -> SnapshotViewController)? { get }
  var fileID: StaticString { get }
  var filePath: StaticString { get }
  var line: UInt { get }
  var column: UInt { get }
}

extension SnapshotViewGenerating {
  public var makeViewControllerAsync: (@MainActor (ConfigurationValue) async throws -> SnapshotViewController)? {
    nil
  }
}
