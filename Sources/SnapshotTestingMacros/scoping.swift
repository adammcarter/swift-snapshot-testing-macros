import Testing

// Set up * without * configuration ...
public protocol SnapshotScoping {
  @MainActor func provideScope() async throws
}

public protocol SnapshotConfigurationScoping {
  associatedtype Value: Sendable

  @MainActor func provideScope(
    for configuration: SnapshotConfiguration<Value>
  ) async throws
}
