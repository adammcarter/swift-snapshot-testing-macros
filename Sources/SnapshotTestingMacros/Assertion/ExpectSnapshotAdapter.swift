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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

    try await runValueOnMainActor(
      SnapshotValueBox(try await makeValue()),
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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

    do {
      try await runValueOnMainActor(
        SnapshotValueBox(await makeValue()),
        named: named,
        function: function,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
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

  /// Shared tail of the plain async overloads: bridge to the main actor structurally so the
  /// assertion runs on the test's task instead of a parked cooperative-pool thread.
  private static func runValueOnMainActor<V: View>(
    _ valueBox: SnapshotValueBox<V>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) async throws {
    try await TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      try await runOnMainActorAsync(context: context) {
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

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping () throws -> V
  ) throws {
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }

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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }
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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }
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
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }
    let resolvedConfiguration = resolvedConfiguration(from: configuration)

    try await TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
      let valueBox = SnapshotValueBox(try await makeValue(resolvedConfiguration.value))

      try await runOnMainActorAsync(context: context) {
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

  static func run<ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotView
  ) {
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }
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

  static func run<ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotViewController
  ) {
    guard
      SnapshotRuntimePreconditions.requireActiveTestContext(
        Test.current,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ) != nil
    else {
      return
    }
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
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
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

  /// Runs `operation` on the main actor and records the snapshot failures it produced after
  /// returning to the caller's side of the hop.
  ///
  /// Off the main thread the hop is `DispatchQueue.main.sync` — a plain queue callout with no
  /// Swift task, where Swift Testing's task-locals (`Test.current`, `Test.Case.current`, the
  /// `withKnownIssue` matcher) all read nil. Failures must therefore never be recorded inside
  /// the hop: they ride back through the result box as values and are recorded here, on the
  /// test's task, so every issue is attributed to the invoking test.
  private static func runOnMainActor(
    context: SnapshotExecutionContext?,
    runtimeState: ResolvedSnapshotRuntimeState = .current,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) throws {
    let failures: [SnapshotFailure]

    if Thread.isMainThread {
      failures = try MainActor.assumeIsolated {
        try runOnMainActorIsolated(
          context: context,
          runtimeState: runtimeState,
          operation: operation
        )
      }
    }
    else {
      let box = SyncMainActorResultBox<[SnapshotFailure]>()
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
      failures = try result.get()
    }

    for failure in failures {
      failure.record()
    }
  }

  /// Runs `operation` on the main actor via a structured hop for the async overloads.
  ///
  /// `await` suspends the caller and resumes on the main actor *as the same task*: the test's
  /// task-locals survive into the render and verification, no cooperative-pool thread is
  /// parked inside `DispatchQueue.main.sync`, and the failures are recorded back on the
  /// test's task after the hop returns.
  private static func runOnMainActorAsync(
    context: SnapshotExecutionContext?,
    runtimeState: ResolvedSnapshotRuntimeState = .current,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) async throws {
    let failures = try await runOnMainActorIsolated(
      context: context,
      runtimeState: runtimeState,
      operation: operation
    )

    for failure in failures {
      failure.record()
    }
  }

  @MainActor
  private static func runOnMainActorIsolated(
    context: SnapshotExecutionContext?,
    runtimeState: ResolvedSnapshotRuntimeState,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) throws -> [SnapshotFailure] {
    if let context {
      return try TaskLocalSnapshotExecutionContext.$current.withValue(context) {
        try runtimeState.withAppliedValues {
          try operation()
        }
      }
    }

    return try runtimeState.withAppliedValues {
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
  ) throws -> [SnapshotFailure] {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    return try runMainActorSnapshot(generator: generator)
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
  ) throws -> [SnapshotFailure] {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    return try runMainActorSnapshot(generator: generator)
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
  ) throws -> [SnapshotFailure] {
    let generator = SnapshotViewGenerator(
      displayName: context.resolvedAssertionName(named: named),
      configuration: configuration,
      makeValue: makeValue,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    return try runMainActorSnapshot(generator: generator)
  }

  @MainActor
  private static func runMainActorSnapshot(
    generator: some SnapshotViewGenerating
  ) throws -> [SnapshotFailure] {
    try collectSnapshotFailuresSync(with: generator)
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
