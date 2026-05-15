import SwiftUI
import Testing

private final class SnapshotValueBox<V>: @unchecked Sendable {
  let value: V

  init(_ value: V) {
    self.value = value
  }
}

private final class SnapshotMakeValueBox<ConfigurationValue: Sendable, V>: @unchecked Sendable {
  let makeValue: (ConfigurationValue) -> V

  init(_ makeValue: @escaping (ConfigurationValue) -> V) {
    self.makeValue = makeValue
  }
}

enum ExpectSnapshotAdapter {
  static func configurationName<T: Sendable>(
    for configuration: SnapshotConfiguration<T>
  ) -> String? {
    if let explicitName = configuration.name {
      return explicitName
    }

    return DerivedSnapshotNames.argumentName(from: configuration.value)
  }

  static func run<V: View, Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (Argument) -> V
  ) {
    let configuration = SnapshotConfiguration(
      name: DerivedSnapshotNames.argumentName(from: argument),
      value: argument
    )

    run(
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

  static func run<V: View>(
    _ value: sending V,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let runtime = ResolvedSnapshotRuntimeState.current
      let displayName = context.resolvedAssertionName(named: named)
      let valueBox = SnapshotValueBox(value)

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: displayName,
            configuration: .none,
            makeValue: { (_: Void) async throws in valueBox.value },
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )

          try await runtime.withAppliedValues {
            try await assertSnapshot(with: generator)
          }
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }

  static func run<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) -> V
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    let resolvedConfiguration = SnapshotConfiguration(
      name: configurationName(for: configuration),
      value: configuration.value
    )
    let makeValueBox = SnapshotMakeValueBox(makeValue)

    TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let runtime = ResolvedSnapshotRuntimeState.current

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: context.resolvedAssertionName(named: named),
            configuration: resolvedConfiguration,
            makeValue: { value async throws in
              makeValueBox.makeValue(value)
            },
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )

          try await runtime.withAppliedValues {
            try await assertSnapshot(with: generator)
          }
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }

  static func run<V: View, A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B) -> V
  ) {
    run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        makeValue(value.0, value.1)
      }
    )
  }

  static func run<V: View, A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B, C) -> V
  ) {
    run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        makeValue(value.0, value.1, value.2)
      }
    )
  }

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }
}
