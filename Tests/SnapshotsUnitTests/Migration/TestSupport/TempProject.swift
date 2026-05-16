import Foundation

struct TempProject {
  let root: String

  static func make() throws -> TempProject {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("snapshot-migration-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return TempProject(root: directory.path)
  }

  @discardableResult
  func write(path: String, contents: String) throws -> String {
    let fileURL = URL(fileURLWithPath: root).appendingPathComponent(path)
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL.path
  }

  func cleanup() {
    try? FileManager.default.removeItem(atPath: root)
  }
}
