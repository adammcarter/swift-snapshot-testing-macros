import Foundation
// SPI dependency: `SnapshotTestingConfiguration.current` is the task-local pointfree's own
// `withSnapshotTesting` and `.snapshots` trait bind. It must be captured on the test's task
// and re-bound on the far side of the adapter's `DispatchQueue.main.sync` hop — a plain queue
// callout where task-locals do not flow — or ambient consumer configuration would be lost
// there. Pointfree exposes it only under `@_spi(Internals)`; the dependency version is pinned.
@_spi(Internals) import SnapshotTesting

struct ResolvedSnapshotRuntimeState {
  let sizes: [SizesSnapshotTrait.Size]
  let theme: ThemeSnapshotTrait.Theme
  let decoratorConfiguration: __SnapshotViewDecoratorConfiguration?
  let strategy: StrategySnapshotTrait.Strategy
  let record: RecordSnapshotTrait.RecordKind?
  let diffTool: DiffToolSnapshotTrait.DiffTool?
  let pointfreeConfiguration: SnapshotTestingConfiguration?

  static var current: Self {
    .init(
      sizes: SizesSnapshotTrait.current,
      theme: ThemeSnapshotTrait.current,
      decoratorConfiguration: __SnapshotViewDecoratorConfiguration.value,
      strategy: StrategySnapshotTrait.current,
      record: RecordSnapshotTrait.current,
      diffTool: DiffToolSnapshotTrait.current,
      pointfreeConfiguration: SnapshotTestingConfiguration.current
    )
  }

  @MainActor
  func withAppliedValues<T>(
    _ operation: () throws -> T
  ) rethrows -> T {
    try SnapshotTestingConfiguration.$current.withValue(pointfreeConfiguration) {
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

  @MainActor
  func withAppliedValues<T>(
    _ operation: () async throws -> T
  ) async rethrows -> T {
    try await SnapshotTestingConfiguration.$current.withValue(pointfreeConfiguration) {
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
}
