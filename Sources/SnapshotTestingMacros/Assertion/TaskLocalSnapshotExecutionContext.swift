enum TaskLocalSnapshotExecutionContext {
  @TaskLocal
  static var current: SnapshotExecutionContext?

  static func withCurrent<T>(
    function: StaticString,
    perform work: (SnapshotExecutionContext) throws -> T
  ) rethrows -> T {
    if let current {
      return try work(current)
    }

    let context = resolveContext(function: function)
    return try $current.withValue(context) {
      try work(context)
    }
  }

  static func withCurrent<T>(
    function: StaticString,
    perform work: (SnapshotExecutionContext) async throws -> T
  ) async rethrows -> T {
    if let current {
      return try await work(current)
    }

    let context = resolveContext(function: function)
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
  /// context. Contexts are deliberately never cached here: they used to be cached under the
  /// raw current-task pointer bits, but the allocator reuses a finished task's allocation for
  /// the next task almost immediately, so new attempts and sequential child tasks frequently
  /// resolved a stale context whose `usedNames` were already populated and unnamed artifact
  /// names silently drifted to "-2"/"-3" suffixes. The residual limitation of the fresh-per-
  /// assertion fallback is narrow: a trait-less test that makes several *unnamed*
  /// `#expectSnapshot` calls resolves the same base name — and, since each fresh context also
  /// restarts the `.N` reference identifier, the same reference file — for each of them
  /// instead of suffixing deterministically. Applying any snapshot trait (which binds the
  /// attempt token) or distinct `named:` arguments restores deterministic naming.
  private static func resolveContext(function: StaticString) -> SnapshotExecutionContext {
    if let token = SnapshotAttemptToken.current {
      return token.executionContext(function: function)
    }

    return SnapshotExecutionContext(function: function)
  }
}
