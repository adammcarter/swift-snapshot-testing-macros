import Foundation

@MainActor
public protocol SnapshotViewGenerating {
  associatedtype ConfigurationValue: Sendable

  var displayName: String { get }
  var configuration: SnapshotConfiguration<ConfigurationValue> { get }
  var makeViewController: @MainActor (ConfigurationValue) async throws -> SnapshotViewController { get }
  var fileID: StaticString { get }
  var filePath: StaticString { get }
  var line: UInt { get }
  var column: UInt { get }
}
