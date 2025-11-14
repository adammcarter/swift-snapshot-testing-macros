import Foundation
import Testing

public struct ThemeSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let theme: Theme

  @TaskLocal static var current = Theme.all

  public var debugDescription: String {
    "theme: \(theme.debugDescription)"
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await ThemeSnapshotTrait.$current.withValue(theme) {
      try await function()
    }
  }

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
