import Foundation

extension SnapshotTrait where Self == ThemeSnapshotTrait {
  /// Allows the snapshot to specify a theme.
  ///
  /// - Parameter theme: The theme to use.
  /// - Returns: A trait that applies the theme.
  public static func theme(
    _ theme: ThemeSnapshotTrait.Theme
  ) -> Self {
    Self(theme: theme)
  }
}
