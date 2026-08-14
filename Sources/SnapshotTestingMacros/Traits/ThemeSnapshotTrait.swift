import Foundation
import Testing

/// A trait that configures the theme (light/dark mode) for snapshot tests.
///
/// Use this trait to specify the theme for your snapshots. You can choose between light mode,
/// dark mode, or both.
///
/// Example:
/// ```swift
/// @Suite
/// struct MySnapshotSuite {
///   @Test(.theme(.dark))
///   func myView() {
///     #expectSnapshot(MyView())
///   }
/// }
/// ```
public struct ThemeSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let theme: Theme

  @TaskLocal
  static var current = Theme.all

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

  /// Represents the theme mode for the snapshot.
  public enum Theme: CaseIterable, Sendable, CustomDebugStringConvertible {
    /// Light mode.
    case light
    /// Dark mode.
    case dark

    /// Both light and dark mode.
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
