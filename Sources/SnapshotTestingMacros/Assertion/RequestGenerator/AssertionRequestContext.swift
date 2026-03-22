import Foundation

struct AssertionRequestContext {
  let name: String
  let traitConfiguration: TraitConfiguration
  let makeSnapshotView: @MainActor () async throws -> SnapshotViewController
  let snapshotDirectory: String
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt

  struct TraitConfiguration {
    let sizes: [SizesSnapshotTrait.Size]
    let theme: ThemeSnapshotTrait.Theme
    let strategy: StrategySnapshotTrait.Strategy
    let precision: Float

    init(
      sizes: [SizesSnapshotTrait.Size],
      theme: ThemeSnapshotTrait.Theme,
      strategy: StrategySnapshotTrait.Strategy,
      precision: Float = 1
    ) {
      self.sizes = sizes
      self.theme = theme
      self.strategy = strategy
      self.precision = min(max(precision, 0), 1)
    }
  }
}
