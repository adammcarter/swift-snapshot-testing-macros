import Foundation

struct ResolvedSnapshotRuntimeState {
  let sizes: [SizesSnapshotTrait.Size]
  let theme: ThemeSnapshotTrait.Theme
  let decoratorConfiguration: __SnapshotViewDecoratorConfiguration?
  let strategy: StrategySnapshotTrait.Strategy
  let record: RecordSnapshotTrait.RecordKind
  let diffTool: DiffToolSnapshotTrait.DiffTool

  static var current: Self {
    .init(
      sizes: SizesSnapshotTrait.current,
      theme: ThemeSnapshotTrait.current,
      decoratorConfiguration: __SnapshotViewDecoratorConfiguration.value,
      strategy: StrategySnapshotTrait.current,
      record: RecordSnapshotTrait.current,
      diffTool: DiffToolSnapshotTrait.current
    )
  }

  @MainActor
  func withAppliedValues<T>(
    _ operation: () async throws -> T
  ) async rethrows -> T {
    try await RecordSnapshotTrait.$current.withValue(record) {
      try await DiffToolSnapshotTrait.$current.withValue(diffTool) {
        try await StrategySnapshotTrait.$current.withValue(strategy) {
          try await ThemeSnapshotTrait.$current.withValue(theme) {
            try await SizesSnapshotTrait.$current.withValue(sizes) {
              try await __SnapshotViewDecoratorConfiguration.$value.withValue(decoratorConfiguration) {
                try await operation()
              }
            }
          }
        }
      }
    }
  }
}
