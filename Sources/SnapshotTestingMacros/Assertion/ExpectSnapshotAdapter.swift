import Foundation
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

private final class SyncMainActorResultBox<T>: @unchecked Sendable {
  let lock = NSLock()
  var result: Result<T, Error>?
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
      let valueBox = SnapshotValueBox(value)
      runOnMainActorRecordingIssues(
        context: context,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: .none,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: { (_: Void) in valueBox.value }
        )
      }
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
      runOnMainActorRecordingIssues(
        context: context,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: .none,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: { (_: Void) in makeView() }
        )
      }
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
      runOnMainActorRecordingIssues(
        context: context,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: .none,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: { (_: Void) in makeViewController() }
        )
      }
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
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> V
  ) {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)
    let resolvedConfiguration = resolvedConfiguration(from: configuration)

    TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      runOnMainActorRecordingIssues(
        context: context,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: resolvedConfiguration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: makeValue
        )
      }
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
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> V
  ) throws {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)
    let resolvedConfiguration = resolvedConfiguration(from: configuration)

    try TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      try runOnMainActor(context: context) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: resolvedConfiguration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: makeValue
        )
      }
    }
  }

  private static func runLazyAsync<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async -> V
  ) async {
    do {
      try await runLazyAsyncThrowing(
        configuration: configuration,
        named: named,
        function: function,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
        makeValue: { value in await makeValue(value) }
      )
    }
    catch {
      recordIssue(
        error,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }

  private static func runLazyAsyncThrowing<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async throws -> V
  ) async throws {
    _ = SnapshotRuntimePreconditions.requireActiveTestContext(Test.current)
    let resolvedConfiguration = resolvedConfiguration(from: configuration)

    try await TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let valueBox = SnapshotValueBox(try await makeValue(resolvedConfiguration.value))

      try runOnMainActor(context: context) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: resolvedConfiguration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeValue: { (_: ConfigurationValue) in valueBox.value }
        )
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
      makeValue: { value in makeValueBox.makeValue(value) }
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
      makeValue: { value in try makeValueBox.makeValue(value) }
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
    await runLazyAsync(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in await makeValue(value) }
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
    try await runLazyAsyncThrowing(
      configuration: configuration,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { value in try await makeValue(value) }
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
      makeValue: { value in makeValue(value.0, value.1) }
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
      makeValue: { value in try makeValue(value.0, value.1) }
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
      makeValue: { value in await makeValue(value.0, value.1) }
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
      makeValue: { value in try await makeValue(value.0, value.1) }
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
      makeValue: { value in makeValue(value.0, value.1, value.2) }
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
      makeValue: { value in try makeValue(value.0, value.1, value.2) }
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
      makeValue: { value in await makeValue(value.0, value.1, value.2) }
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
      makeValue: { value in try await makeValue(value.0, value.1, value.2) }
    )
  }

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }

  private static func resolvedConfiguration<ConfigurationValue: Sendable>(
    from configuration: SnapshotConfiguration<ConfigurationValue>
  ) -> SnapshotConfiguration<ConfigurationValue> {
    SnapshotConfiguration(
      name: configurationName(for: configuration),
      value: configuration.value
    )
  }

  private static func runOnMainActorRecordingIssues(
    context: SnapshotExecutionContext?,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    operation: @escaping @MainActor () throws -> Void
  ) {
    let runtimeState = ResolvedSnapshotRuntimeState.current

    do {
      try runOnMainActor(
        context: context,
        runtimeState: runtimeState,
        operation: operation
      )
    }
    catch {
      recordIssue(
        error,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }

  private static func runOnMainActor(
    context: SnapshotExecutionContext?,
    runtimeState: ResolvedSnapshotRuntimeState = .current,
    operation: @escaping @MainActor () throws -> Void
  ) throws {
    if Thread.isMainThread {
      try MainActor.assumeIsolated {
        try runOnMainActorIsolated(
          context: context,
          runtimeState: runtimeState,
          operation: operation
        )
      }
      return
    }

    let box = SyncMainActorResultBox<Void>()
    DispatchQueue.main.sync {
      let result = Result {
        try MainActor.assumeIsolated {
          try runOnMainActorIsolated(
            context: context,
            runtimeState: runtimeState,
            operation: operation
          )
        }
      }

      box.lock.withLock {
        box.result = result
      }
    }

    let result =
      box.lock.withLock { box.result } ?? .failure(
        SnapshotError(message: "Failed to execute snapshot assertion on the main thread.")
      )
    _ = try result.get()
  }

  @MainActor
  private static func runOnMainActorIsolated(
    context: SnapshotExecutionContext?,
    runtimeState: ResolvedSnapshotRuntimeState,
    operation: @escaping @MainActor () throws -> Void
  ) throws {
    if let context {
      try TaskLocalSnapshotExecutionContext.$current.withValue(context) {
        try runtimeState.withAppliedValues {
          try operation()
        }
      }
      return
    }

    try runtimeState.withAppliedValues {
      try operation()
    }
  }

  @MainActor
  private static func runMainActorSnapshot<V: View, ConfigurationValue: Sendable>(
    context: SnapshotExecutionContext,
    named: String?,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> V
  ) throws {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    try runMainActorSnapshot(generator: generator)
  }

  @MainActor
  private static func runMainActorSnapshot<ConfigurationValue: Sendable>(
    context: SnapshotExecutionContext,
    named: String?,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotView
  ) throws {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    try runMainActorSnapshot(generator: generator)
  }

  @MainActor
  private static func runMainActorSnapshot<ConfigurationValue: Sendable>(
    context: SnapshotExecutionContext,
    named: String?,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
  ) throws {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    try runMainActorSnapshot(generator: generator)
  }

  @MainActor
  private static func runMainActorSnapshot(
    generator: some SnapshotViewGenerating
  ) throws {
    try assertSnapshotSync(with: generator)
  }

  private static func recordIssue(
    _ error: Error,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    Issue.record(
      error,
      sourceLocation: .init(
        fileID: fileID.description,
        filePath: filePath.description,
        line: Int(line),
        column: Int(column)
      )
    )
  }
}
