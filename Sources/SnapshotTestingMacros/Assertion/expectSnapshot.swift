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
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
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
