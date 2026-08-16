import Foundation

/// This is an implementation detail of the snapshot trait machinery. Do not use this type
/// directly. It is `public` only for macro-generated code and is hidden from documentation.
@_documentation(visibility: private)
// swiftlint:disable:next type_name
public protocol __SnapshotTestScopingViewDecorator: SnapshotTestScoping {
  func updateConfiguration(_ configuration: inout __SnapshotViewDecoratorConfiguration) async throws
}

extension __SnapshotTestScopingViewDecorator {
  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    var configuration = __SnapshotViewDecoratorConfiguration.value ?? .init()

    try await updateConfiguration(&configuration)

    try await __SnapshotViewDecoratorConfiguration.$value.withValue(configuration, operation: function)
  }
}
