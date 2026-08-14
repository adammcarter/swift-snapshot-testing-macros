import Foundation

enum SnapshotNameNormalizer {
  static func folderComponent(from string: String) -> String {
    string
      .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
      .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
  }

  /// Normalizes a display name while preserving the slash-as-subfolder convention: each
  /// `/`-separated segment is normalized as its own folder component, and segments that
  /// normalize to nothing are dropped (`"Menu/Item"` stays `"Menu/Item"`, `"Some name"`
  /// becomes `"Some-name"`).
  static func folderPath(from string: String) -> String {
    string
      .split(separator: "/", omittingEmptySubsequences: true)
      .map(String.init)
      .map(folderComponent(from:))
      .filter { $0.isEmpty == false }
      .joined(separator: "/")
  }
}
