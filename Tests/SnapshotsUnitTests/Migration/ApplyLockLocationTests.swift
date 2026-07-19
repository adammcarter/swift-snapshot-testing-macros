import Foundation
import Testing

@testable import SnapshotMigrationSupport

/**
 The lock file is deliberately never unlinked — `flock` owns the mutual exclusion, and the
 earlier unlink-to-reclaim approach let one process destroy another's lock and admit two
 concurrent `--apply` runs. Because it therefore outlives the run, it must not live inside the
 consumer's repository, where it shows up in `git status` immediately after migrating and can be
 committed by accident.
 */
@Suite
struct ApplyLockLocationTests {
  @Test("Acquiring a lock leaves nothing behind in the project being migrated")
  func lockFileIsNotWrittenIntoTheProjectRoot() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let lock = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { lock.release() }

    let entries = try FileManager.default.contentsOfDirectory(atPath: fixture.root)
    #expect(entries.isEmpty, "migrating left \(entries) in the consumer's repository")
    #expect(!FileManager.default.fileExists(atPath: fixture.root + "/.snapshot-migration.lock"))
  }

  @Test("The lock still serialises two runs against the same project")
  func lockStillExcludesAConcurrentRun() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    let first = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    defer { first.release() }

    #expect(throws: ApplyLockError.self) {
      _ = try ApplyLock.acquire(projectRoot: fixture.root, timeoutSeconds: 0)
    }
  }

  @Test("Two different projects lock independently")
  func distinctProjectsDoNotContendForOneLock() throws {
    let first = try TempProject.make()
    defer { first.cleanup() }
    let second = try TempProject.make()
    defer { second.cleanup() }

    let firstLock = try ApplyLock.acquire(projectRoot: first.root, timeoutSeconds: 0)
    defer { firstLock.release() }
    let secondLock = try ApplyLock.acquire(projectRoot: second.root, timeoutSeconds: 0)
    defer { secondLock.release() }

    #expect(ApplyLock.lockPath(forProjectRoot: first.root) != ApplyLock.lockPath(forProjectRoot: second.root))
  }

  /// The same project must resolve to the same lock however its path is spelled, or two runs
  /// invoked with differently-spelled roots would both think they hold the lock.
  @Test("A project's lock path is stable across equivalent spellings of its root")
  func lockPathIsStableForEquivalentRoots() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    #expect(
      ApplyLock.lockPath(forProjectRoot: fixture.root)
        == ApplyLock.lockPath(forProjectRoot: fixture.root + "/")
    )
  }
}
