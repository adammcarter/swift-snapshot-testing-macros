import SnapshotSupport

/// Thrown when an async generator's synchronous `makeViewController` is invoked without first
/// resolving the async value through `assertSnapshot(with:)`.
struct SnapshotAsyncMakeValueError: Error, CustomStringConvertible {
  var description: String {
    "Async snapshot values must be resolved via 'assertSnapshot(with:)' before the synchronous snapshot pipeline runs."
  }
}

public struct SnapshotViewGenerator<ConfigurationValue: Sendable>: SnapshotViewGenerating {
  public let displayName: String
  public let configuration: SnapshotConfiguration<ConfigurationValue>
  public let makeViewController: @MainActor (ConfigurationValue) throws -> SnapshotViewController
  /// Non-nil when the generator was built from an async `makeValue` (legacy async
  /// `@SnapshotTest` functions and suites with async inits). `assertSnapshot(with:)` awaits it
  /// once and feeds the resolved value into the synchronous pipeline.
  public let makeViewControllerAsync: (@MainActor (ConfigurationValue) async throws -> SnapshotViewController)?
  public let fileID: StaticString
  public let filePath: StaticString
  public let line: UInt
  public let column: UInt

  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.configuration = configuration
    self.makeViewController = makeValue
    self.makeViewControllerAsync = nil
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }

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
    self.makeViewController = { _ in throw SnapshotAsyncMakeValueError() }
    self.makeViewControllerAsync = makeValue
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }

  init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeViewController: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController,
    makeViewControllerAsync: (@MainActor (ConfigurationValue) async throws -> SnapshotViewController)?,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.configuration = configuration
    self.makeViewController = makeViewController
    self.makeViewControllerAsync = makeViewControllerAsync
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}

/// Rebuilds `generator` with `displayName` in place of its baked-in display name.
///
/// This is an implementation detail of the legacy `@SnapshotSuite` expansion: when two or more
/// `@SnapshotTest` functions would fall back to the same suite display name, the generated
/// tests disambiguate their reference artifacts as `<suite name>/<function name>` through this
/// hook. Do not call it directly.
@_documentation(visibility: private)
@MainActor
// swiftlint:disable:next identifier_name
public func __overridingDisplayName<G: SnapshotViewGenerating>(
  of generator: G,
  with displayName: String
) -> any SnapshotViewGenerating {
  SnapshotViewGenerator<G.ConfigurationValue>(
    displayName: displayName,
    configuration: generator.configuration,
    makeViewController: generator.makeViewController,
    makeViewControllerAsync: generator.makeViewControllerAsync,
    fileID: generator.fileID,
    filePath: generator.filePath,
    line: generator.line,
    column: generator.column
  )
}
