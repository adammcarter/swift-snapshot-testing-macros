import Foundation

extension SnapshotTrait where Self == ThemeSnapshotTrait {
  /// Allows the snapshot to specify a theme, eg isolate between light mode or dark mode, or all.
  public static func theme(
    _ theme: ThemeSnapshotTrait.Theme
  ) -> Self {
    Self(theme: theme)
  }
}
