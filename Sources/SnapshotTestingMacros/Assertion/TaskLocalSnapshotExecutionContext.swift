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

    let context = SnapshotExecutionContext(function: function)
    return try $current.withValue(context) {
      try work(context)
    }
  }
}
