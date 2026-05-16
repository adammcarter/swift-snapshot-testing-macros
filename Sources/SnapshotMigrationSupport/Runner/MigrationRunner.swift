import Foundation

public enum MigrationExitCode: Int {
  case success = 0
  case migrationFailure = 1
  case applySafetyFailure = 2
  case invalidUsage = 3
  case strictSkipFailure = 4
}

public struct MigrationRunOutcome {
  public let report: MigrationReport
  public let exitCode: MigrationExitCode

  public init(report: MigrationReport, exitCode: MigrationExitCode) {
    self.report = report
    self.exitCode = exitCode
  }
}

public struct MigrationRunner {
  public init() {}

  public func run(options: MigrationOptions) async throws -> MigrationExitCode {
    try await runWithOutcome(options: options).exitCode
  }

  public func runWithOutcome(options: MigrationOptions) async throws -> MigrationRunOutcome {
    let scan = try ProjectScanner().scan(
      projectRoot: options.projectRoot,
      maxFileSizeBytes: options.maxFileSizeBytes
    )

    let runID = "run-\(UUID().uuidString)"
    let rewriter = SnapshotMigrationRewriter()
    let replacer = AtomicFileReplacer()

    var stagingStore: RunStagingStore?
    var hadMigrationFailures = false
    var hadApplyFailures = false
    var pendingApplies: [PendingApply] = []

    var migratedDeclarations = 0
    var skippedDeclarations = 0
    var failedDeclarations = 0
    var filesAttemptedApply = 0
    var filesApplied = 0
    var filesApplyFailed = 0
    var filesPreconditionFailed = 0
    var filesUnsafeNonRegular = 0
    var issueLines: [String] = []

    for file in scan.candidateFiles {
      let rewriteResult: RewriteResult
      do {
        rewriteResult = try rewriter.rewrite(source: file.contents)
      } catch {
        hadMigrationFailures = true
        failedDeclarations += 1
        issueLines.append("\(file.relativePath):1 <unknown> syntax-parse-failed unable to rewrite declaration")
        continue
      }

      if !rewriteResult.reasons.isEmpty {
        hadMigrationFailures = true
        skippedDeclarations += 1
        for reason in rewriteResult.reasons {
          issueLines.append("\(file.relativePath):\(reason.line) <unknown> \(reason.code) \(reason.message)")
        }
        continue
      }

      guard rewriteResult.changed else {
        skippedDeclarations += 1
        continue
      }

      if options.mode == .apply || options.keepTemp {
        do {
          if stagingStore == nil {
            stagingStore = try RunStagingStore.create(runID: runID)
          }
          try stagingStore?.stage(
            relativePath: file.relativePath,
            contents: rewriteResult.output,
            maxStagedBytes: options.maxStagedBytes
          )
        } catch {
          hadMigrationFailures = true
          failedDeclarations += 1
          issueLines.append("\(file.relativePath):1 <unknown> temp-storage-cap-exceeded unable to stage rewritten output")
          continue
        }
      }

      pendingApplies.append(
        PendingApply(
          absolutePath: file.absolutePath,
          relativePath: file.relativePath,
          expectedHash: SHA256Hasher.hash(file.contents),
          rewrittenContents: rewriteResult.output
        )
      )
      migratedDeclarations += 1
    }

    if options.mode == .apply && !hadMigrationFailures {
      var applyLock: ApplyLock?
      do {
        applyLock = try ApplyLock.acquire(
          projectRoot: options.projectRoot,
          timeoutSeconds: options.applyLockTimeoutSeconds
        )
      } catch {
        hadApplyFailures = true
        filesAttemptedApply = pendingApplies.count
        filesApplyFailed = pendingApplies.count
        failedDeclarations += migratedDeclarations
        migratedDeclarations = 0
        issueLines.append(".snapshot-migration.lock:1 <lock> apply-lock-held failed to acquire apply lock")
      }
      defer { applyLock?.release() }

      if !hadApplyFailures {
        for pendingApply in pendingApplies {
          filesAttemptedApply += 1
          do {
            try replacer.replace(
              path: pendingApply.absolutePath,
              expectedHash: pendingApply.expectedHash,
              newContents: pendingApply.rewrittenContents
            )
            filesApplied += 1
          } catch let error as AtomicReplaceError {
            hadApplyFailures = true
            filesApplyFailed += 1
            migratedDeclarations = max(0, migratedDeclarations - 1)
            failedDeclarations += 1
            let reasonCode: String
            switch error {
            case .preconditionFailed:
              filesPreconditionFailed += 1
              reasonCode = "apply-precondition-failed"
            case .unsafeNonRegularFile:
              filesUnsafeNonRegular += 1
              reasonCode = "unsafe-nonregular-file"
            case .writeFailed:
              reasonCode = "atomic-write-failed"
              break
            }
            issueLines.append("\(pendingApply.relativePath):1 <unknown> \(reasonCode) apply failed")
          } catch {
            hadApplyFailures = true
            filesApplyFailed += 1
            migratedDeclarations = max(0, migratedDeclarations - 1)
            failedDeclarations += 1
            issueLines.append("\(pendingApply.relativePath):1 <unknown> atomic-write-failed apply failed")
          }
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

    let candidateDeclarations = scan.candidateFiles.count
    let migrationPercentage: Int
    if candidateDeclarations == 0 {
      migrationPercentage = 100
    } else {
      migrationPercentage = Int((Double(migratedDeclarations) / Double(candidateDeclarations) * 100.0).rounded(.down))
    }

    let report = MigrationReport(
      reportSchemaVersion: 1,
      runID: runID,
      projectRoot: options.projectRoot,
      filesScanned: scan.filesScanned,
      candidateFiles: scan.candidateFiles.count,
      candidateDeclarations: candidateDeclarations,
      migratedDeclarations: migratedDeclarations,
      skippedDeclarations: skippedDeclarations,
      failedDeclarations: failedDeclarations,
      migrationPercentage: migrationPercentage,
      filesAttemptedApply: filesAttemptedApply,
      filesApplied: filesApplied,
      filesApplyFailed: filesApplyFailed,
      filesPreconditionFailed: filesPreconditionFailed,
      filesUnsafeNonRegular: filesUnsafeNonRegular,
      issueLines: issueLines
    )

    var exitCode = report.resolveExitCode(failOnSkips: options.failOnSkips)
    if options.mode == .apply, hadMigrationFailures, exitCode == .success {
      exitCode = .migrationFailure
    }
    if options.mode == .dryRun, report.candidateDeclarations > 0, exitCode == .success {
      exitCode = .migrationFailure
    }

    return MigrationRunOutcome(report: report, exitCode: exitCode)
  }
}

private struct PendingApply {
  let absolutePath: String
  let relativePath: String
  let expectedHash: String
  let rewrittenContents: String
}
