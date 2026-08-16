import Foundation

struct AssertionRequestContext {
  let name: String
  let configurationName: String?
  let traitConfiguration: TraitConfiguration
  let makeSnapshotView: @MainActor () throws -> SnapshotViewController
  let snapshotDirectory: String
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt

  struct TraitConfiguration {
    let sizes: [SizesSnapshotTrait.Size]
    let theme: ThemeSnapshotTrait.Theme
    let strategy: StrategySnapshotTrait.Strategy
  }
}
