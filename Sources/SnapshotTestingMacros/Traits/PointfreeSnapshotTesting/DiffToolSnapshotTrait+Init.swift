import Foundation

extension SnapshotTrait where Self == DiffToolSnapshotTrait {
  /// Configures the diff tool to use when snapshot tests fail.
  ///
  /// - Parameter diffTool: The diff tool configuration to use.
  /// - Returns: A trait that sets the diff tool.
  public static func diffTool(_ diffTool: DiffToolSnapshotTrait.DiffTool) -> Self {
    Self(diffTool: diffTool)
  }
}
