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

/// Serializes `--apply` runs via `flock(2)` on a persistent lock file.
///
/// Design choice: the lock file is never unlinked. Earlier versions created
/// the file with `O_CREAT | O_EXCL` and reclaimed stale locks by unlinking,
/// which had a race: two waiters could both observe the same stale PID, one
/// would unlink-and-recreate, and the other would then unlink the fresh lock,
/// letting two `--apply` runs proceed concurrently. With `flock` the kernel
/// owns the mutual exclusion (the lock dies with the process, so there is no
/// stale state to reclaim) and because no code path ever unlinks the file,
/// there is no window in which one process can destroy another's lock. The
/// holder's PID is written into the file for diagnostics only; it carries no
/// locking semantics.
public final class ApplyLock: @unchecked Sendable {
  private let lockPath: String
  private let fileDescriptor: CInt
  private let releaseGuard = NSLock()
  private var released = false

  private init(lockPath: String, fileDescriptor: CInt) {
    self.lockPath = lockPath
    self.fileDescriptor = fileDescriptor
  }

  public static func acquire(projectRoot: String, timeoutSeconds: Int) throws -> ApplyLock {
    let lockPath = URL(fileURLWithPath: projectRoot).appendingPathComponent(".snapshot-migration.lock").path
    let deadline = Date().addingTimeInterval(TimeInterval(max(0, timeoutSeconds)))

    while true {
      let fileDescriptor = open(lockPath, O_CREAT | O_RDWR | O_CLOEXEC, mode_t(0o600))
      if fileDescriptor < 0 {
        throw ApplyLockError.lockCreateFailed(lockPath)
      }

      if flock(fileDescriptor, LOCK_EX | LOCK_NB) == 0 {
        writeOwnerPIDForDiagnostics(to: fileDescriptor)
        return ApplyLock(lockPath: lockPath, fileDescriptor: fileDescriptor)
      }

      let flockErrno = errno
      _ = close(fileDescriptor)

      if flockErrno != EWOULDBLOCK && flockErrno != EAGAIN {
        throw ApplyLockError.lockCreateFailed(lockPath)
      }

      if Date() >= deadline {
        throw ApplyLockError.lockHeld(lockPath)
      }

      usleep(100_000)
    }
  }

  /// Releases the lock by closing the file descriptor, which drops the
  /// `flock`. Idempotent: repeated calls are no-ops, so a stale reference can
  /// never close a reused descriptor belonging to a newer lock holder. The
  /// lock file itself is intentionally left in place (see type docs).
  public func release() {
    releaseGuard.lock()
    defer { releaseGuard.unlock() }
    guard !released else { return }
    released = true
    _ = close(fileDescriptor)
  }

  private static func writeOwnerPIDForDiagnostics(to fileDescriptor: CInt) {
    _ = ftruncate(fileDescriptor, 0)
    let ownerPID = "\(getpid())"
    _ = ownerPID.withCString { ptr in
      write(fileDescriptor, ptr, strlen(ptr))
    }
  }
}
