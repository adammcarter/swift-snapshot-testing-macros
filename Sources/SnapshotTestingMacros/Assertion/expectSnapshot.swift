import SwiftUI

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  _ value: sending V,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  ExpectSnapshotAdapter.run(
    value,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  _ value: @autoclosure @escaping @MainActor () -> SnapshotView,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  ExpectSnapshotAdapter.run(
    view: value,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  _ value: @autoclosure @escaping @MainActor () -> SnapshotViewController,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  ExpectSnapshotAdapter.run(
    viewController: value,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping () -> V
) {
  ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping () throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping () async -> V
) async {
  await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping () async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (Argument) -> V
) {
  ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (Argument) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (Argument) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (Argument) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (ConfigurationValue) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (ConfigurationValue) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (ConfigurationValue) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (ConfigurationValue) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B, C) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B, C) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B, C) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping (A, B, C) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}
