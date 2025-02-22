import Foundation

extension ThemeSnapshotTrait {
  public enum Theme: CaseIterable, Sendable, CustomDebugStringConvertible {
    case light
    case dark

    /// Combination mask for both light and dark mode
    case all

    public var debugDescription: String {
      switch self {
        case .light: "light"
        case .dark: "dark"
        case .all: "all"
      }
    }
  }
}
