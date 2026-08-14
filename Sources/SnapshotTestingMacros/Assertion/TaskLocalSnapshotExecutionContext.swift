enum TaskLocalSnapshotExecutionContext {
  @TaskLocal
  static var current: SnapshotExecutionContext?

  static func withCurrent<T>(
    function: StaticString,
    isParameterizedCase: Bool = false,
    perform work: (SnapshotExecutionContext) throws -> T
  ) rethrows -> T {
    if let current {
      return try work(current)
    }

    let context = resolveContext(
      function: function,
      isParameterizedCase: isParameterizedCase
    )
    return try $current.withValue(context) {
      try work(context)
    }
  }

  static func withCurrent<T>(
    function: StaticString,
    isParameterizedCase: Bool = false,
    perform work: (SnapshotExecutionContext) async throws -> T
  ) async rethrows -> T {
    if let current {
      return try await work(current)
    }

    let context = resolveContext(
      function: function,
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
  /// context and therefore uses the function's base name. Callers that need multiple distinct
  /// assertions must provide explicit names or apply a snapshot trait to share an attempt scope.
  private static func resolveContext(
    function: StaticString,
    isParameterizedCase: Bool
  ) -> SnapshotExecutionContext {
    if let token = SnapshotAttemptToken.current {
      return token.executionContext(function: function)
    }

    return SnapshotExecutionContext(
      function: function,
      isParameterizedCase: isParameterizedCase
    )
  }
}
