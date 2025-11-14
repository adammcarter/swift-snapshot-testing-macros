import Foundation

@available(*, message: "This is an implementation detail. Do not use this type directly.")
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
