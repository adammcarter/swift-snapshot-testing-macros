import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum AtomicReplaceError: Error, Equatable {
  case preconditionFailed
  case unsafeNonRegularFile
  case writeFailed(String)
}

public struct AtomicFileReplacer {
  public init() {}

  public func replace(path: String, expectedHash: String, newContents: String) throws {
    let originalFileMode = try regularFileMode(forPath: path)
    let fileURL = URL(fileURLWithPath: path)
    let currentData = try Data(contentsOf: fileURL)
    let actualHash = SHA256Hasher.hash(currentData)
    guard actualHash == expectedHash else {
      throw AtomicReplaceError.preconditionFailed
    }

    let parentDirectory = fileURL.deletingLastPathComponent().path
    let tempPath = parentDirectory + "/\(fileURL.lastPathComponent).snapshot-migration.\(getpid()).\(UUID().uuidString).tmp"
    let newData = Data(newContents.utf8)

    var tempFD: CInt = -1
    var renamed = false
    do {
      tempFD = open(tempPath, O_WRONLY | O_CREAT | O_EXCL, originalFileMode)
      guard tempFD >= 0 else {
        throw AtomicReplaceError.writeFailed("create-temp-failed")
      }

      try writeAll(newData, to: tempFD)

      guard fsync(tempFD) == 0 else {
        throw AtomicReplaceError.writeFailed("fsync-temp-failed")
      }

      guard close(tempFD) == 0 else {
        throw AtomicReplaceError.writeFailed("close-temp-failed")
      }
      tempFD = -1

      guard rename(tempPath, path) == 0 else {
        throw AtomicReplaceError.writeFailed("rename-failed")
      }
      renamed = true

      let directoryFD = open(parentDirectory, O_RDONLY)
      if directoryFD >= 0 {
        _ = fsync(directoryFD)
        _ = close(directoryFD)
      }
    } catch let error as AtomicReplaceError {
      if tempFD >= 0 {
        _ = close(tempFD)
      }
      if !renamed {
        _ = unlink(tempPath)
      }
      throw error
    } catch {
      if tempFD >= 0 {
        _ = close(tempFD)
      }
      if !renamed {
        _ = unlink(tempPath)
      }
      throw AtomicReplaceError.writeFailed("unknown-write-error")
    }
  }

  private func regularFileMode(forPath path: String) throws -> mode_t {
    var fileStat = stat()
    guard lstat(path, &fileStat) == 0 else {
      throw AtomicReplaceError.unsafeNonRegularFile
    }

    let fileType = fileStat.st_mode & mode_t(S_IFMT)
    guard fileType == mode_t(S_IFREG) else {
      throw AtomicReplaceError.unsafeNonRegularFile
    }

    return fileStat.st_mode & mode_t(0o7777)
  }

  private func writeAll(_ data: Data, to fileDescriptor: CInt) throws {
    try data.withUnsafeBytes { rawBuffer in
      guard var pointer = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }

      var remaining = data.count
      while remaining > 0 {
        let wrote = write(fileDescriptor, pointer, remaining)
        guard wrote > 0 else {
          throw AtomicReplaceError.writeFailed("write-temp-failed")
        }
        remaining -= Int(wrote)
        pointer = pointer.advanced(by: Int(wrote))
      }
    }
  }
}
