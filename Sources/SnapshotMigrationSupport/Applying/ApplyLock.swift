import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum ApplyLockError: Error, Equatable {
  case lockHeld(String)
  case lockCreateFailed(String)
}

public struct ApplyLock {
  private let lockPath: String
  private let fileDescriptor: CInt

  public static func acquire(projectRoot: String, timeoutSeconds: Int) throws -> ApplyLock {
    let lockPath = URL(fileURLWithPath: projectRoot).appendingPathComponent(".snapshot-migration.lock").path
    let deadline = Date().addingTimeInterval(TimeInterval(max(0, timeoutSeconds)))

    while true {
      let fileDescriptor = open(lockPath, O_CREAT | O_EXCL | O_RDWR, mode_t(0o600))
      if fileDescriptor >= 0 {
        let ownerPID = "\(getpid())"
        _ = ownerPID.withCString { ptr in
          write(fileDescriptor, ptr, strlen(ptr))
        }
        return ApplyLock(lockPath: lockPath, fileDescriptor: fileDescriptor)
      }

      if errno != EEXIST {
        throw ApplyLockError.lockCreateFailed(lockPath)
      }

      if reclaimStaleLockIfNeeded(atPath: lockPath) {
        continue
      }

      if Date() >= deadline {
        throw ApplyLockError.lockHeld(lockPath)
      }

      usleep(100_000)
    }
  }

  public func release() {
    _ = close(fileDescriptor)
    _ = unlink(lockPath)
  }

  private static func reclaimStaleLockIfNeeded(atPath path: String) -> Bool {
    guard let ownerText = try? String(contentsOfFile: path, encoding: .utf8) else { return false }
    let trimmedOwner = ownerText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let ownerPID = Int32(trimmedOwner), ownerPID > 0 else { return false }

    if kill(ownerPID, 0) == -1, errno == ESRCH {
      return unlink(path) == 0
    }
    return false
  }
}
