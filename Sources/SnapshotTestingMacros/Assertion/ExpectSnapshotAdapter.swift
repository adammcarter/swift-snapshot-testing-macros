import Foundation
import SwiftUI
import Testing

/// Tags an error thrown by the user's builder so the sync throwing SwiftUI overload can tell
/// it apart from a pipeline error once both have crossed the main-actor hop.
///
/// That overload rethrows builder errors but records pipeline errors; the two used to be
/// distinguishable by position, because the builder ran eagerly on the caller's thread. Now
/// that every SwiftUI builder is resolved inside the hop like its platform counterpart, the
/// distinction is carried by this wrapper instead of by evaluation order.
private struct BuilderError: Error {
  let underlying: Error
}

/// Carries the hop's outcome back across `DispatchQueue.main.sync`.
///
/// The invariant that makes this sound is the queue callout's ordering: `main.sync` blocks
/// the caller until the block finishes and publishes a happens-before edge from the block's
/// write to the caller's read, so `result` is written exactly once before it is read exactly
/// once and is never accessed concurrently. The lock is belt-and-braces around that edge.
private final class SyncMainActorResultBox<T>: @unchecked Sendable {
  let lock = NSLock()
  var result: Result<T, Error>?
}

/// How a core run obtains the assertion's effective configuration.
private enum ConfigurationSource<ConfigurationValue: Sendable> {
  /// Use the configuration exactly as given — the no-configuration overloads' `.none`.
  case direct(SnapshotConfiguration<ConfigurationValue>)

  /// Derive a name for unnamed configurations via
  /// `ExpectSnapshotAdapter.resolvedConfiguration(from:context:...)`, which also guards
  /// derived names against lossy-normalization collisions; a `nil` resolution records an
  /// issue and skips the assertion.
  case derived(SnapshotConfiguration<ConfigurationValue>)
}

/// Funnels every `#expectSnapshot` overload onto one generic core path.
///
/// The public overload surface normalizes down to two axes:
/// - **payload**: each `run` shim converts its value/closure flavor (SwiftUI `View`,
///   `SnapshotView`, `SnapshotViewController`; direct value, autoclosure, closure, argument,
///   configuration, tuple) into the canonical
///   `@MainActor (ConfigurationValue) throws -> SnapshotViewController` builder consumed by
///   ``runMainActorSnapshot(context:named:configuration:fileID:filePath:line:column:makeViewController:)``.
/// - **effect**: the shim picks the matching core — ``runSync`` / ``runSyncThrowing`` /
///   ``runAsync`` / ``runAsyncThrowing`` — which owns the preconditions, execution-context
///   binding, configuration resolution, main-actor hop, and failure recording.
///
/// Error policy, one shape per effect flavor:
/// - Non-throwing overloads (sync and async) **record** every error as an issue at the
///   assertion's source location; nothing escapes.
/// - Throwing overloads **rethrow** errors to the caller — both `makeValue` errors and
///   pipeline errors (request generation and rendering inside the hop). The one historical
///   exception is the no-configuration sync throwing overload, which rethrows only its
///   `makeValue` errors (tagged as ``BuilderError`` as they cross the hop) and records
///   pipeline errors like its non-throwing sibling.
/// - Snapshot verification failures are never thrown: every flavor carries them across the
///   hop as ``SnapshotFailure`` values and records them on the test's task.
enum ExpectSnapshotAdapter {
  static func configurationName<T: Sendable>(
    for configuration: SnapshotConfiguration<T>
  ) -> String? {
    if let explicitName = configuration.name {
      return explicitName
    }

    return DerivedSnapshotNames.argumentName(from: configuration.value)
  }

  // MARK: - SwiftUI value and closure shims

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () -> V
  ) {
    runSync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in makeSnapshotHostingController(for: makeValue()) }
    )
  }

  /// The historical hybrid of the throwing overloads: `makeValue`'s own errors rethrow, but
  /// the assertion runs the recording sync core, so pipeline errors are recorded instead of
  /// rethrown. `makeValue` is resolved inside the main-actor hop like every other builder, so
  /// its errors are tagged as ``BuilderError`` to stay distinguishable on the way back out.
  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () throws -> V
  ) throws {
    do {
      try runSyncThrowing(
        source: .direct(.none),
        named: named,
        function: function,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
        makeViewController: { _ in
          let value: V

          do {
            value = try makeValue()
          }
          catch {
            throw BuilderError(underlying: error)
          }

          return makeSnapshotHostingController(for: value)
        }
      )
    }
    catch let error as BuilderError {
      throw error.underlying
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

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async -> V
  ) async {
    await runAsync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in makeSnapshotHostingController(for: await makeValue()) }
    )
  }

  static func run<V: View>(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async throws -> V
  ) async throws {
    try await runAsyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in makeSnapshotHostingController(for: try await makeValue()) }
    )
  }

  static func run<V: View>(
    value makeValue: @escaping @MainActor () -> V,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    run(
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  // MARK: - Platform view shims

  static func run(
    view makeView: @escaping @MainActor () -> SnapshotView,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    runSync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in SnapshotInjectedViewController(view: makeView()) }
    )
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
    runSync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in makeViewController() }
    )
  }

  static func run(
    view makeView: @escaping @MainActor () throws -> SnapshotView,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) throws {
    try runSyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in
        SnapshotInjectedViewController(view: try makeView())
      }
    )
  }

  static func run(
    viewController makeViewController: @escaping @MainActor () throws -> SnapshotViewController,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) throws {
    try runSyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in try makeViewController() }
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () -> SnapshotView
  ) {
    run(
      view: makeValue,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () -> SnapshotViewController
  ) {
    run(
      viewController: makeValue,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () throws -> SnapshotView
  ) throws {
    try run(
      view: makeValue,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () throws -> SnapshotViewController
  ) throws {
    try run(
      viewController: makeValue,
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async -> SnapshotView
  ) async {
    await runAsync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in
        SnapshotInjectedViewController(view: await makeValue())
      }
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async -> SnapshotViewController
  ) async {
    await runAsync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in await makeValue() }
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async throws -> SnapshotView
  ) async throws {
    try await runAsyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in
        SnapshotInjectedViewController(view: try await makeValue())
      }
    )
  }

  static func run(
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor () async throws -> SnapshotViewController
  ) async throws {
    try await runAsyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in try await makeValue() }
    )
  }

  // MARK: - Argument shims

  static func run<V: View, Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) -> V
  ) {
    // `name: nil` routes the argument through the shared derivation in
    // `resolvedConfiguration(from:context:...)`, which also guards derived names against
    // lossy-normalization collisions across test cases.
    let configuration = SnapshotConfiguration(
      name: nil,
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
    makeValue: @escaping @MainActor (Argument) throws -> V
  ) throws {
    // `name: nil` routes the argument through the shared derivation in
    // `resolvedConfiguration(from:context:...)`, which also guards derived names against
    // lossy-normalization collisions across test cases.
    let configuration = SnapshotConfiguration(
      name: nil,
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
    makeValue: @escaping @MainActor (Argument) async -> V
  ) async {
    // `name: nil` routes the argument through the shared derivation in
    // `resolvedConfiguration(from:context:...)`, which also guards derived names against
    // lossy-normalization collisions across test cases.
    let configuration = SnapshotConfiguration(
      name: nil,
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
    makeValue: @escaping @MainActor (Argument) async throws -> V
  ) async throws {
    // `name: nil` routes the argument through the shared derivation in
    // `resolvedConfiguration(from:context:...)`, which also guards derived names against
    // lossy-normalization collisions across test cases.
    let configuration = SnapshotConfiguration(
      name: nil,
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

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) -> SnapshotView
  ) {
    run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) -> SnapshotViewController
  ) {
    run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) throws -> SnapshotView
  ) throws {
    try run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) throws -> SnapshotViewController
  ) throws {
    try run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) async -> SnapshotView
  ) async {
    await run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) async -> SnapshotViewController
  ) async {
    await run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) async throws -> SnapshotView
  ) async throws {
    try await run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  static func run<Argument: Sendable>(
    argument: Argument,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (Argument) async throws -> SnapshotViewController
  ) async throws {
    try await run(
      configuration: SnapshotConfiguration(name: nil, value: argument),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
    )
  }

  // MARK: - Configuration shims

  static func run<V: View, ConfigurationValue: Sendable>(
    configuration: SnapshotConfiguration<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (ConfigurationValue) -> V
  ) {
    runSync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: makeValue(value))
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
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> V
  ) throws {
    try runSyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: try makeValue(value))
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
    makeValue: @escaping @MainActor (ConfigurationValue) async -> V
  ) async {
    await runAsync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: await makeValue(value))
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
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> V
  ) async throws {
    try await runAsyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: try await makeValue(value))
      }
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
    runSync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in SnapshotInjectedViewController(view: makeValue(value)) }
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
    makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotViewController
  ) {
    runSync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: makeValue
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
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotView
  ) throws {
    try runSyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        SnapshotInjectedViewController(view: try makeValue(value))
      }
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
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
  ) throws {
    try runSyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: makeValue
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
    makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotView
  ) async {
    await runAsync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        SnapshotInjectedViewController(view: await makeValue(value))
      }
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
    makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotViewController
  ) async {
    await runAsync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in await makeValue(value) }
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
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotView
  ) async throws {
    try await runAsyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        SnapshotInjectedViewController(view: try await makeValue(value))
      }
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
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
  ) async throws {
    try await runAsyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: makeValue
    )
  }

  // MARK: - Tuple configuration shims

  static func run<V: View, A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) -> V
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
    makeValue: @escaping @MainActor (A, B) throws -> V
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
    makeValue: @escaping @MainActor (A, B) async -> V
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
    makeValue: @escaping @MainActor (A, B) async throws -> V
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
    makeValue: @escaping @MainActor (A, B, C) -> V
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
    makeValue: @escaping @MainActor (A, B, C) throws -> V
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
    makeValue: @escaping @MainActor (A, B, C) async -> V
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
    makeValue: @escaping @MainActor (A, B, C) async throws -> V
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) -> SnapshotView
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) throws -> SnapshotView
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) throws -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) async -> SnapshotView
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) async -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) async throws -> SnapshotView
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

  static func run<A: Sendable, B: Sendable>(
    configuration: SnapshotConfiguration<(A, B)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B) async throws -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) -> SnapshotView
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotView
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) async -> SnapshotView
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) async -> SnapshotViewController
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotView
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

  static func run<A: Sendable, B: Sendable, C: Sendable>(
    // swiftlint:disable:next large_tuple
    configuration: SnapshotConfiguration<(A, B, C)>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotViewController
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

  // MARK: - Naming

  static func displayName(named: String?, baseName: String) -> String {
    SnapshotExecutionContext.resolvedAssertionName(named: named, baseName: baseName)
  }

  /// Resolves the configuration's reference name, deriving one from the value when no
  /// explicit name was given.
  ///
  /// Derivation is guarded against lossy-normalization collisions: when this call site
  /// already derived the same name from a differently-described value — two cases of one
  /// parameterized test whose values fold to one name, silently sharing a single reference
  /// file — an issue is recorded on the current test and `nil` is returned so the caller
  /// skips the assertion instead of comparing against (or overwriting) the other case's
  /// reference. Explicit names are the user's deliberate choice and are never guarded.
  static func resolvedConfiguration<ConfigurationValue: Sendable>(
    from configuration: SnapshotConfiguration<ConfigurationValue>,
    context: SnapshotExecutionContext,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) -> SnapshotConfiguration<ConfigurationValue>? {
    if configuration.name != nil {
      return configuration
    }

    let derivedName = DerivedSnapshotNames.argumentName(from: configuration.value)
    let valueDescription = String(describing: configuration.value)
    let callSite = "\(filePath):\(line):\(column)"

    // Collisions are decided on the reference file the name reaches, not on the name itself:
    // the default macOS filesystem is case-insensitive, so "Card" and "card" are one file.
    // Both keys fold, or a case-differing loop iteration would be misreported as a collision.
    let nameKey = SnapshotNameNormalizer.referenceFileKey(from: derivedName)
    let occurrence = context.nextOccurrenceIndex(forKey: "\(callSite)|\(nameKey)")

    let conflictingDescription = SnapshotConfigurationNameCollisions.shared.conflictingValueDescription(
      callSite: callSite,
      derivedName: nameKey,
      occurrence: occurrence,
      valueDescription: valueDescription
    )

    if let conflictingDescription {
      Issue.record(
        Comment(
          rawValue: """
            Snapshot configuration name collision: values described as \
            '\(conflictingDescription)' and '\(valueDescription)' both derive the snapshot \
            name '\(derivedName)' at this call site, so their test cases would share one \
            reference file. Give each configuration a distinct explicit name via \
            SnapshotConfiguration(name:value:). The assertion was skipped.
            """
        ),
        sourceLocation: .init(
          fileID: fileID.description,
          filePath: filePath.description,
          line: Int(line),
          column: Int(column)
        )
      )

      return nil
    }

    return SnapshotConfiguration(name: derivedName, value: configuration.value)
  }

  private static func resolveConfiguration<ConfigurationValue: Sendable>(
    from source: ConfigurationSource<ConfigurationValue>,
    context: SnapshotExecutionContext,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) -> SnapshotConfiguration<ConfigurationValue>? {
    switch source {
      case .direct(let configuration):
        configuration
      case .derived(let configuration):
        resolvedConfiguration(
          from: configuration,
          context: context,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
    }
  }

  // MARK: - Effect cores

  /// The recording sync core: pipeline errors are recorded as issues instead of escaping.
  private static func runSync<ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
  ) {
    do {
      try runSyncThrowing(
        source: source,
        named: named,
        function: function,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
        makeViewController: makeViewController
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

  /// The rethrowing sync core: verification failures are recorded on the test's task, every
  /// error is rethrown to the caller.
  private static func runSyncThrowing<ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
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

    try TaskLocalSnapshotExecutionContext.withCurrent(
      function: function,
      isParameterizedCase: Test.Case.current?.isParameterized == true
    ) { context in
      guard
        let configuration = resolveConfiguration(
          from: source,
          context: context,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      else {
        return
      }

      try runOnMainActor(context: context) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: configuration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeViewController: makeViewController
        )
      }
    }
  }

  /// The recording async core: pipeline errors are recorded as issues instead of escaping.
  ///
  /// Every async builder — SwiftUI and UIKit/AppKit alike — is main-actor isolated and is
  /// resolved by the async generator on the same structured hop as the snapshot pipeline.
  private static func runAsync<ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
  ) async {
    do {
      try await runAsyncThrowing(
        source: source,
        named: named,
        function: function,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
        makeViewController: makeViewController
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

  /// The rethrowing async core: verification failures are recorded on the test's task, every
  /// error — from `makeViewController` or the pipeline — is rethrown to the caller.
  private static func runAsyncThrowing<ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
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

    try await TaskLocalSnapshotExecutionContext.withCurrent(
      function: function,
      isParameterizedCase: Test.Case.current?.isParameterized == true
    ) { context in
      guard
        let configuration = resolveConfiguration(
          from: source,
          context: context,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      else {
        return
      }

      try await runOnMainActorAsyncOperation(context: context) {
        try await runMainActorSnapshotAsync(
          context: context,
          named: named,
          configuration: configuration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeViewController: makeViewController
        )
      }
    }
  }

  // MARK: - Main-actor bridging

  /// Runs `operation` on the main actor and records the snapshot failures it produced after
  /// returning to the caller's side of the hop.
  ///
  /// Off the main thread the hop is `DispatchQueue.main.sync` — a plain queue callout with no
  /// Swift task, where Swift Testing's task-locals (`Test.current`, `Test.Case.current`, the
  /// `withKnownIssue` matcher) all read nil. Failures must therefore never be recorded inside
  /// the hop: they ride back through the result box as values and are recorded here, on the
  /// test's task, so every issue is attributed to the invoking test.
  private static func runOnMainActor(
    context: SnapshotExecutionContext,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) throws {
    let runtimeState = ResolvedSnapshotRuntimeState.current
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

      guard let result = box.lock.withLock({ box.result }) else {
        throw SnapshotError(message: "Failed to execute snapshot assertion on the main thread.")
      }
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
    context: SnapshotExecutionContext,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) async throws {
    let runtimeState = ResolvedSnapshotRuntimeState.current

    let failures = try await runOnMainActorIsolated(
      context: context,
      runtimeState: runtimeState,
      operation: operation
    )

    for failure in failures {
      failure.record()
    }
  }

  /// Async counterpart for an async main-actor snapshot builder.
  private static func runOnMainActorAsyncOperation(
    context: SnapshotExecutionContext,
    operation: @escaping @MainActor () async throws -> [SnapshotFailure]
  ) async throws {
    let runtimeState = ResolvedSnapshotRuntimeState.current

    let failures = try await runOnMainActorIsolatedAsync(
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
    context: SnapshotExecutionContext,
    runtimeState: ResolvedSnapshotRuntimeState,
    operation: @escaping @MainActor () throws -> [SnapshotFailure]
  ) throws -> [SnapshotFailure] {
    try TaskLocalSnapshotExecutionContext.$current.withValue(context) {
      try runtimeState.withAppliedValues {
        try operation()
      }
    }
  }

  @MainActor
  private static func runOnMainActorIsolatedAsync(
    context: SnapshotExecutionContext,
    runtimeState: ResolvedSnapshotRuntimeState,
    operation: @escaping @MainActor () async throws -> [SnapshotFailure]
  ) async throws -> [SnapshotFailure] {
    try await TaskLocalSnapshotExecutionContext.$current.withValue(context) {
      try await runtimeState.withAppliedValues {
        try await operation()
      }
    }
  }

  /// The single main-actor tail of every overload: builds the view generator around the
  /// canonical view-controller closure and collects the assertion's failures as values, to be
  /// recorded on the caller's side of the hop.
  @MainActor
  private static func runMainActorSnapshot<ConfigurationValue: Sendable>(
    context: SnapshotExecutionContext,
    named: String?,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
  ) throws -> [SnapshotFailure] {
    // An `argument:`/configuration assertion supplies case identity through its configuration.
    // The shipped Apple Testing module exposes only whether a case is parameterized, not its
    // argument values, so a bare assertion cannot safely invent or validate per-case identity.
    // `named:` labels the assertion but cannot prove that every case chose a distinct value.
    // Fail closed before rendering whenever the configuration carries no case identity.
    let disambiguatesUnnamedCase = configuration.name == nil
    if disambiguatesUnnamedCase, context.isParameterizedCase {
      return [
        SnapshotFailure(
          message: """
            #expectSnapshot in a parameterized test has no stable case identity. Pass the case \
            value through #expectSnapshot(argument:) or SnapshotConfiguration. The named: \
            argument labels an assertion but cannot prove that every case uses a distinct value. \
            The assertion was skipped instead of sharing a reference file with another case.
            """,
          error: nil,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      ]
    }

    let displayName = context.resolvedAssertionName(
      named: named
    )

    let generator = SnapshotViewGenerator(
      displayName: displayName,
      configuration: configuration,
      makeValue: makeViewController,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )

    return try collectSnapshotFailuresSync(with: generator)
  }

  @MainActor
  private static func runMainActorSnapshotAsync<ConfigurationValue: Sendable>(
    context: SnapshotExecutionContext,
    named: String?,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeViewController: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
  ) async throws -> [SnapshotFailure] {
    let disambiguatesUnnamedCase = configuration.name == nil
    if disambiguatesUnnamedCase, context.isParameterizedCase {
      return [
        SnapshotFailure(
          message: """
            #expectSnapshot in a parameterized test has no stable case identity. Pass the case \
            value through #expectSnapshot(argument:) or SnapshotConfiguration. The named: \
            argument labels the assertion but cannot prove that every case uses a distinct value. \
            The assertion was skipped instead of sharing a reference file with another case.
            """,
          error: nil,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      ]
    }

    let displayName = context.resolvedAssertionName(
      named: named
    )

    let generator = SnapshotViewGenerator(
      displayName: displayName,
      configuration: configuration,
      makeValue: makeViewController,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
    let resolvedGenerator = try await resolvedSyncViewGenerator(from: generator)

    return try collectSnapshotFailuresSync(with: resolvedGenerator)
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
