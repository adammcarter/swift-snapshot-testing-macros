import Foundation
import SnapshotTesting

public struct DiffToolSnapshotTrait: SnapshotTrait {
  let diffTool: DiffTool

  public var debugDescription: String {
    "diffTool: \(diffTool)"
  }

  public typealias DiffTool = SnapshotTesting.SnapshotTestingConfiguration.DiffTool
}
