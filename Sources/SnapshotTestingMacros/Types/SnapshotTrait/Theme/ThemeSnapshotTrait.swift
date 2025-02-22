import Foundation

public struct ThemeSnapshotTrait: SnapshotTrait {
  let theme: Theme

  public var debugDescription: String {
    "theme: \(theme.debugDescription)"
  }
}
