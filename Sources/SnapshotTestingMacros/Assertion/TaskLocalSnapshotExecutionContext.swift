enum TaskLocalSnapshotExecutionContext {
  @TaskLocal
  static var current: SnapshotExecutionContext?

  static func withCurrent<T>(
    function: StaticString,
    line: UInt = #line,
    column: UInt = #column,
    isParameterizedCase: Bool = false,
    perform work: (SnapshotExecutionContext) throws -> T
  ) rethrows -> T {
    if let current {
      return try work(current)
    }

    let context = resolveContext(
      function: function,
      line: line,
      column: column,
      isParameterizedCase: isParameterizedCase
    )
    return try $current.withValue(context) {
      try work(context)
    }
  }

  static func withCurrent<T>(
    function: StaticString,
    line: UInt = #line,
    column: UInt = #column,
    isParameterizedCase: Bool = false,
    perform work: (SnapshotExecutionContext) async throws -> T
  ) async rethrows -> T {
    if let current {
      return try await work(current)
    }

    let context = resolveContext(
      function: function,
      line: line,
      column: column,
      isParameterizedCase: isParameterizedCase
    )
    return try await $current.withValue(context) {
      try await work(context)
    }
  }

  /// Resolves the execution context for one assertion.
  ///
  /// When a ``SnapshotTestScoping`` trait wrapped the current attempt, the context lives on
  /// the attempt's ``SnapshotAttemptToken``: every assertion in the attempt — including ones
  /// made from child tasks, which inherit the task-local token — shares it, and a new attempt
  /// gets a fresh token and therefore a fresh context.
  ///
  /// Without a token (a bare `@Test` without any snapshot trait) every assertion gets a fresh
  /// context whose source call site is its stable identity. Contexts are deliberately never
  /// cached here: they used to be cached under the
  /// raw current-task pointer bits, but the allocator reuses a finished task's allocation for
  /// the next task almost immediately, so new attempts and sequential child tasks frequently
  /// resolved a stale context whose `usedNames` were already populated and unnamed artifact
  /// names silently drifted to "-2"/"-3" suffixes. The residual limitation of the fresh-per-
  /// assertion fallback therefore uses the exact line and column inside the source file that
  /// already owns the snapshot directory, not unsafe execution identity: distinct source
  /// assertions resolve distinct references, while repetitions of one source assertion resolve
  /// the same reference across runs.
  private static func resolveContext(
    function: StaticString,
    line: UInt,
    column: UInt,
    isParameterizedCase: Bool
  ) -> SnapshotExecutionContext {
    if let token = SnapshotAttemptToken.current {
      return token.executionContext(function: function)
    }

    return SnapshotExecutionContext(
      function: function,
      isParameterizedCase: isParameterizedCase,
      fallbackSourceLocationIdentity: "L\(line)C\(column)"
    )
  }
}
