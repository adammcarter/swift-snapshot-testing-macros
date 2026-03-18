import Foundation

enum SnapshotNameNormalizer {
  static func folderComponent(from string: String) -> String {
    string
      .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
      .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
  }
}
