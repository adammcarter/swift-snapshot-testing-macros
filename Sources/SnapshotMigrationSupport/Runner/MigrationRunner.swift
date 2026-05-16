import Foundation

public enum MigrationExitCode: Int {
  case success = 0
  case migrationFailure = 1
  case applySafetyFailure = 2
  case invalidUsage = 3
  case strictSkipFailure = 4
}

public struct MigrationRunner {
  public init() {}

  public func run(options: MigrationOptions) async throws -> MigrationExitCode {
    let scan = try ProjectScanner().scan(
      projectRoot: options.projectRoot,
      maxFileSizeBytes: options.maxFileSizeBytes
    )

    let rewriter = SnapshotMigrationRewriter()
    let replacer = AtomicFileReplacer()
    var stagingStore: RunStagingStore?
    var hadMigrationFailures = false
    var hadApplyFailures = false
    var pendingApplies: [PendingApply] = []

    for file in scan.candidateFiles {
      let rewriteResult: RewriteResult
      do {
        rewriteResult = try rewriter.rewrite(source: file.contents)
      } catch {
        hadMigrationFailures = true
        continue
      }

      if !rewriteResult.reasons.isEmpty {
        hadMigrationFailures = true
      }

      guard rewriteResult.changed else { continue }

      if options.mode == .apply || options.keepTemp {
        do {
          if stagingStore == nil {
            stagingStore = try RunStagingStore.create()
          }
          try stagingStore?.stage(
            relativePath: file.relativePath,
            contents: rewriteResult.output,
            maxStagedBytes: options.maxStagedBytes
          )
        } catch {
          hadMigrationFailures = true
          continue
        }
      }

      pendingApplies.append(
        PendingApply(
          absolutePath: file.absolutePath,
          expectedHash: SHA256Hasher.hash(file.contents),
          rewrittenContents: rewriteResult.output
        )
      )
    }

    if options.mode == .apply && !hadMigrationFailures {
      var applyLock: ApplyLock?
      do {
        applyLock = try ApplyLock.acquire(
          projectRoot: options.projectRoot,
          timeoutSeconds: options.applyLockTimeoutSeconds
        )
      } catch {
        return .applySafetyFailure
      }
      defer { applyLock?.release() }

      for pendingApply in pendingApplies {
        do {
          try replacer.replace(
            path: pendingApply.absolutePath,
            expectedHash: pendingApply.expectedHash,
            newContents: pendingApply.rewrittenContents
          )
        } catch {
          hadApplyFailures = true
        }
      }
    }

    if options.mode == .apply,
       !options.keepTemp,
       !hadMigrationFailures,
       !hadApplyFailures
    {
      stagingStore?.remove()
    }

    if hadApplyFailures {
      return .applySafetyFailure
    }

    if hadMigrationFailures {
      return .migrationFailure
    }

    if options.mode == .dryRun {
      return scan.candidateFiles.isEmpty ? .success : .migrationFailure
    }

    return .success
  }
}

private struct PendingApply {
  let absolutePath: String
  let expectedHash: String
  let rewrittenContents: String
}
