import Foundation
import SwiftUI
import Testing

/// Moves one non-`Sendable` payload into the adapter's main-actor hop.
///
/// The invariant that makes every use sound is exclusive hand-off: the payload is placed in
/// the box on the test's side of the hop, the caller never touches it again, and the hop
/// guarantees the payload is consumed on the main actor with a happens-before edge from the
/// caller (`DispatchQueue.main.sync`, `MainActor.assumeIsolated` on the main thread, or a
/// structured `await`) — so no two threads ever access the payload concurrently. The boxed
/// payload is either a snapshot value rendered exactly once inside the hop, or the user's
/// `makeValue` closure invoked exactly once inside the hop. `sending` cannot express this
/// hand-off across the oldest supported toolchains (Swift 6.0/6.1 region analysis rejects
/// the capture), hence `@unchecked`.
private final class UncheckedSendableBox<Wrapped>: @unchecked Sendable {
  let wrapped: Wrapped

  init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }
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
///   exception is the no-configuration sync throwing overload, which evaluates `makeValue`
///   eagerly on the caller's thread (rethrowing its errors) and then runs the recording sync
///   core, so pipeline errors are recorded like its non-throwing sibling.
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

    // `makeValue` runs on the caller's thread, before the main-actor hop.
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

  /// The historical hybrid of the throwing overloads: `makeValue` is evaluated eagerly on
  /// the caller's thread and its errors rethrow, but the assertion itself runs the recording
  /// sync core, so pipeline errors are recorded instead of rethrown.
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

    // `makeValue` is awaited on the test's task, before the execution context is bound.
    let valueBox = UncheckedSendableBox(await makeValue())

    await runAsync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { _ in valueBox.wrapped }
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

    // `makeValue` is awaited on the test's task, before the execution context is bound.
    let valueBox = UncheckedSendableBox(try await makeValue())

    try await runAsyncThrowing(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: { _ in valueBox.wrapped }
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
    let valueBox = UncheckedSendableBox(value)

    runSync(
      source: .direct(.none),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { _ in makeSnapshotHostingController(for: valueBox.wrapped) }
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

  // MARK: - Argument shims

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
    makeValue: @escaping (Argument) throws -> V
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
    makeValue: @escaping (Argument) async -> V
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
    makeValue: @escaping (Argument) async throws -> V
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

  // MARK: - Configuration shims

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
    let makeValueBox = UncheckedSendableBox(makeValue)

    runSync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: makeValueBox.wrapped(value))
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
    let makeValueBox = UncheckedSendableBox(makeValue)

    try runSyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeViewController: { value in
        makeSnapshotHostingController(for: try makeValueBox.wrapped(value))
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
    await runAsync(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
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
    try await runAsyncThrowing(
      source: .derived(configuration),
      named: named,
      function: function,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column,
      makeValue: makeValue
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

  // MARK: - Tuple configuration shims

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
    let occurrence = context.nextOccurrenceIndex(forKey: "\(callSite)|\(derivedName)")

    let conflictingDescription = SnapshotConfigurationNameCollisions.shared.conflictingValueDescription(
      callSite: callSite,
      derivedName: derivedName,
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

    try TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
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
  private static func runAsync<V: View, ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
    named: String?,
    function: StaticString,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt,
    makeValue: @escaping (ConfigurationValue) async throws -> V
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
        makeValue: makeValue
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
  /// error — from `makeValue` or the pipeline — is rethrown to the caller.
  ///
  /// `makeValue` is awaited on the test's task inside the execution-context binding, before
  /// the main-actor hop; only the resolved value crosses to the main actor.
  private static func runAsyncThrowing<V: View, ConfigurationValue: Sendable>(
    source: ConfigurationSource<ConfigurationValue>,
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

    try await TaskLocalSnapshotExecutionContext.withCurrent(function: function) { context in
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

      let valueBox = UncheckedSendableBox(try await makeValue(configuration.value))

      try await runOnMainActorAsync(context: context) {
        try runMainActorSnapshot(
          context: context,
          named: named,
          configuration: configuration,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column,
          makeViewController: { _ in makeSnapshotHostingController(for: valueBox.wrapped) }
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
    // An `argument:`/configuration assertion already distinguishes each parameterized case by
    // its configuration name, so the per-case discriminator is suppressed there to keep those
    // reference names unchanged; unnamed, non-configuration assertions fold it in.
    let disambiguatesUnnamedCase = configuration.name == nil
    let displayName = context.resolvedAssertionName(
      named: named,
      disambiguatesUnnamedCase: disambiguatesUnnamedCase
    )

    // Guard the folded discriminator name against lossy-normalization collisions across cases,
    // the same way the `argument:` path guards its derived configuration names. The conflict is
    // returned as a failure (not recorded here) so it surfaces on the test's task past the hop.
    if named == nil, disambiguatesUnnamedCase,
      let conflictingDescription = context.conflictingCaseDescription(
        forResolvedName: displayName,
        callSite: "\(filePath):\(line):\(column)"
      )
    {
      return [
        SnapshotFailure(
          message: """
            Snapshot reference name collision: this parameterized test's cases described as \
            '\(conflictingDescription)' and '\(context.caseDescription ?? "")' both derive the \
            snapshot name '\(displayName)', so they would share one reference file. Give the \
            assertion an explicit distinct name via #expectSnapshot(..., named:) per case, or \
            switch to the argument:/SnapshotConfiguration form. The assertion was skipped.
            """,
          error: nil,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      ]
    }

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
