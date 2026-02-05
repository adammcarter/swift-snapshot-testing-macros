import SnapshotSupport

extension SnapshotViewGenerator {
  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotView,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      displayName: displayName,
      configuration: configuration,
      makeValue: {
        let view = try await makeValue($0)

        return with(SnapshotViewController()) {
          $0.view = view
        }
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}
