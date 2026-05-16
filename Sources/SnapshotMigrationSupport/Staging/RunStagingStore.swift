import Foundation

public enum RunStagingStoreError: Error, Equatable {
  case invalidRelativePath(String)
  case tempStorageCapExceeded
  case writeFailed(String)
}

public struct RunStagingStore {
  public let root: String
  public private(set) var stagedBytes: Int = 0
  public private(set) var capExceeded = false

  public init(root: String, fileManager: FileManager = .default) throws {
    self.root = root
    try fileManager.createDirectory(atPath: root, withIntermediateDirectories: true)
    try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: root)
  }

  public static func create(runID: String = UUID().uuidString, fileManager: FileManager = .default) throws -> RunStagingStore {
    let rootURL = URL(fileURLWithPath: "/tmp", isDirectory: true)
      .appendingPathComponent("snapshot-migration", isDirectory: true)
      .appendingPathComponent(runID, isDirectory: true)

    return try RunStagingStore(root: rootURL.path, fileManager: fileManager)
  }

  public mutating func stage(
    relativePath: String,
    contents: String,
    maxStagedBytes: Int,
    fileManager: FileManager = .default
  ) throws {
    guard !relativePath.hasPrefix("/") else {
      throw RunStagingStoreError.invalidRelativePath(relativePath)
    }

    if capExceeded {
      throw RunStagingStoreError.tempStorageCapExceeded
    }

    let bytes = contents.utf8.count
    guard stagedBytes + bytes <= maxStagedBytes else {
      capExceeded = true
      throw RunStagingStoreError.tempStorageCapExceeded
    }

    let targetURL = URL(fileURLWithPath: root).appendingPathComponent(relativePath)
    try fileManager.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)

    do {
      try contents.write(to: targetURL, atomically: false, encoding: .utf8)
    } catch {
      throw RunStagingStoreError.writeFailed(targetURL.path)
    }

    stagedBytes += bytes
  }

  public func remove(fileManager: FileManager = .default) {
    try? fileManager.removeItem(atPath: root)
  }
}
