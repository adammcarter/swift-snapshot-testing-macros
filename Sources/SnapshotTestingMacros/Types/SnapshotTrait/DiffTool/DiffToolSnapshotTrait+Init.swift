import Foundation

extension SnapshotTrait where Self == DiffToolSnapshotTrait {
  public static func diffTool(_ diffTool: DiffToolSnapshotTrait.DiffTool) -> Self {
    Self(diffTool: diffTool)
  }

  public static var `default`: Self {
    Self(diffTool: .default)
  }
}
