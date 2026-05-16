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
    try write(path: path, data: Data(contents.utf8))
  }

  @discardableResult
  func write(path: String, data: Data) throws -> String {
    let fileURL = URL(fileURLWithPath: root).appendingPathComponent(path)
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: fileURL)
    return fileURL.path
  }

  func setPOSIXPermissions(path: String, permissions: Int) throws {
    let rootURL = URL(fileURLWithPath: root)
    let filePath: String
    if path == "." || path.isEmpty {
      filePath = rootURL.path
    } else {
      filePath = rootURL.appendingPathComponent(path).path
    }
    try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: filePath)
  }

  func cleanup() {
    try? FileManager.default.removeItem(atPath: root)
  }
}
