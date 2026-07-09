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
    _ operation: () throws -> T
  ) rethrows -> T {
    try RecordSnapshotTrait.$current.withValue(record) {
      try DiffToolSnapshotTrait.$current.withValue(diffTool) {
        try StrategySnapshotTrait.$current.withValue(strategy) {
          try ThemeSnapshotTrait.$current.withValue(theme) {
            try SizesSnapshotTrait.$current.withValue(sizes) {
              try __SnapshotViewDecoratorConfiguration.$value.withValue(decoratorConfiguration) {
                try operation()
              }
            }
          }
        }
      }
    }
  }
}
