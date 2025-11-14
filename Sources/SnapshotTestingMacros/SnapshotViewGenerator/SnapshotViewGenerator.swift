import SnapshotSupport

public struct SnapshotViewGenerator<ConfigurationValue: Sendable>: SnapshotViewGenerating {
  public let displayName: String
  public let configuration: SnapshotConfiguration<ConfigurationValue>
  public let makeViewController: @MainActor (ConfigurationValue) async throws -> SnapshotViewController
  public let fileID: StaticString
  public let filePath: StaticString
  public let line: UInt
  public let column: UInt

  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.configuration = configuration
    self.makeViewController = makeValue
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}
