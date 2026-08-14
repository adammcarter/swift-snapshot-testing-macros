import Foundation

enum SnapshotNameNormalizer {
  static func folderComponent(from string: String) -> String {
    string
      .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
      .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
  }

  /// The identity two names must differ in to reach different reference files.
  ///
  /// Normalization preserves case but macOS filesystems do not: `Card_light.1.png` and
  /// `card_light.1.png` are one file by default, so uniqueness has to be decided on the
  /// case-folded component. Only the comparison folds — recorded names keep the casing their
  /// author wrote, because folding those would rename every reference already on disk.
  static func referenceFileKey(from string: String) -> String {
    folderComponent(from: string).lowercased()
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
