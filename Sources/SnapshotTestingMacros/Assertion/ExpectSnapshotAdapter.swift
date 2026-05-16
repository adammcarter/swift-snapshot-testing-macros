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

private final class SnapshotThrowingMakeValueBox<ConfigurationValue: Sendable, V>: @unchecked Sendable {
  let makeValue: (ConfigurationValue) throws -> V

  init(_ makeValue: @escaping (ConfigurationValue) throws -> V) {
    self.makeValue = makeValue
  }
}

private final class SnapshotAsyncMakeValueBox<ConfigurationValue: Sendable, V>: @unchecked Sendable {
  let makeValue: (ConfigurationValue) async -> V

  init(_ makeValue: @escaping (ConfigurationValue) async -> V) {
    self.makeValue = makeValue
  }
}

private final class SnapshotAsyncThrowingMakeValueBox<ConfigurationValue: Sendable, V>: @unchecked Sendable {
  let makeValue: (ConfigurationValue) async throws -> V

  init(_ makeValue: @escaping (ConfigurationValue) async throws -> V) {
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

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping () -> V
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    run(
      makeValue(),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping () async throws -> V
  ) async throws {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    run(
      try await makeValue(),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping () async -> V
  ) async {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    run(
      await makeValue(),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping () throws -> V
  ) throws {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    run(
      try makeValue(),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
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

  static func run<V: View, Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (Argument) throws -> V
  ) throws {
    let configuration = SnapshotConfiguration(
      name: DerivedSnapshotNames.argumentName(from: argument),
      value: argument
    )

    try run(
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

  static func run<V: View, Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (Argument) async -> V
  ) async {
    let configuration = SnapshotConfiguration(
      name: DerivedSnapshotNames.argumentName(from: argument),
      value: argument
    )

    await run(
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

  static func run<V: View, Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (Argument) async throws -> V
  ) async throws {
    let configuration = SnapshotConfiguration(
      name: DerivedSnapshotNames.argumentName(from: argument),
      value: argument
    )

    try await run(
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

  static func run(
    view makeView: @escaping @MainActor () -> SnapshotView,
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

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: displayName,
            configuration: .none,
            makeValue: { (_: Void) async throws in makeView() },
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

  static func run(
    viewController makeViewController: @escaping @MainActor () -> SnapshotViewController,
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

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: displayName,
            configuration: .none,
            makeValue: { (_: Void) async throws in makeViewController() },
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

  private static func runLazy<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async throws -> V
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    let resolvedConfiguration = SnapshotConfiguration(
      name: configurationName(for: configuration),
      value: configuration.value
    )
    let makeValueBox = SnapshotAsyncThrowingMakeValueBox(makeValue)

    TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let runtime = ResolvedSnapshotRuntimeState.current

      SyncSnapshotBridge.run(
        {
          let generator = SnapshotViewGenerator(
            displayName: context.resolvedAssertionName(named: named),
            configuration: resolvedConfiguration,
            makeValue: { value async throws in
              try await makeValueBox.makeValue(value)
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

  private static func runLazyThrowing<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async throws -> V
  ) throws {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)

    let resolvedConfiguration = SnapshotConfiguration(
      name: configurationName(for: configuration),
      value: configuration.value
    )
    let makeValueBox = SnapshotAsyncThrowingMakeValueBox(makeValue)

    try TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let runtime = ResolvedSnapshotRuntimeState.current

      try SyncSnapshotBridge.runThrowing {
        let generator = SnapshotViewGenerator(
          displayName: context.resolvedAssertionName(named: named),
          configuration: resolvedConfiguration,
          makeValue: { value async throws in
            try await makeValueBox.makeValue(value)
          },
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )

        try await runtime.withAppliedValues {
          try await assertSnapshot(with: generator)
        }
      }
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
    let makeValueBox = SnapshotMakeValueBox(makeValue)

    runLazy(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        makeValueBox.makeValue(value)
      }
    )
  }

  static func run<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) throws -> V
  ) throws {
    let makeValueBox = SnapshotThrowingMakeValueBox(makeValue)

    try runLazyThrowing(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try makeValueBox.makeValue(value)
      }
    )
  }

  static func run<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async -> V
  ) async {
    let makeValueBox = SnapshotAsyncMakeValueBox(makeValue)

    runLazy(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        await makeValueBox.makeValue(value)
      }
    )
  }

  static func run<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async throws -> V
  ) async throws {
    let makeValueBox = SnapshotAsyncThrowingMakeValueBox(makeValue)

    try runLazyThrowing(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try await makeValueBox.makeValue(value)
      }
    )
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

  static func run<V: View, A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B) throws -> V
  ) throws {
    try run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try makeValue(value.0, value.1)
      }
    )
  }

  static func run<V: View, A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B) async -> V
  ) async {
    await run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        await makeValue(value.0, value.1)
      }
    )
  }

  static func run<V: View, A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B) async throws -> V
  ) async throws {
    try await run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try await makeValue(value.0, value.1)
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

  static func run<V: View, A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (A, B, C) throws -> V
  ) throws {
    try run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try makeValue(value.0, value.1, value.2)
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
    makeValue: @escaping (A, B, C) async -> V
  ) async {
    await run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        await makeValue(value.0, value.1, value.2)
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
    makeValue: @escaping (A, B, C) async throws -> V
  ) async throws {
    try await run(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in
        try await makeValue(value.0, value.1, value.2)
      }
    )
  }

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }
}
