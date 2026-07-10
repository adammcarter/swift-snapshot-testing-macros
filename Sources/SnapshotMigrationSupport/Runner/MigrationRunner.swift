import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum MigrationExitCode: Int, Sendable {
  case success = 0
  case migrationFailure = 1
  case applySafetyFailure = 2
  case invalidUsage = 3
  case strictSkipFailure = 4
}

public struct MigrationRunOutcome: Sendable {
  public let report: MigrationReport
  public let exitCode: MigrationExitCode
  /// Path of the run's staging directory when it was intentionally kept (via
  /// `--keep-temp`, or as the recovery copy after a failed apply run); `nil`
  /// when the staging directory was removed or never created.
  public let keptStagingRoot: String?

  public init(report: MigrationReport, exitCode: MigrationExitCode, keptStagingRoot: String? = nil) {
    self.report = report
    self.exitCode = exitCode
    self.keptStagingRoot = keptStagingRoot
  }
}

public struct MigrationRunner {
  public init() {}

  /// Maps an error thrown while creating the staging store or staging a rewritten
  /// file to the issue-line reason code reported for that file. Only a genuine
  /// `--max-staged-bytes` breach may report `temp-storage-cap-exceeded`; directory
  /// creation/permission failures and write failures get their own codes.
  static func stagingIssueCode(for error: Error) -> String {
    switch error {
    case RunStagingStoreError.tempStorageCapExceeded:
      return "temp-storage-cap-exceeded"
    case RunStagingStoreError.writeFailed:
      return "staging-write-failed"
    case RunStagingStoreError.invalidRelativePath:
      return "staging-invalid-path"
    default:
      return "staging-setup-failed"
    }
  }

  public func run(options: MigrationOptions) async throws -> MigrationExitCode {
    try await runWithOutcome(options: options).exitCode
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func runWithOutcome(options: MigrationOptions) async throws -> MigrationRunOutcome {
    let clock = ContinuousClock()
    let totalTimingStart = try startPhase(clock: clock)

    let scanTimingStart = try startPhase(clock: clock)
    let scan = try ProjectScanner().scan(
      projectRoot: options.projectRoot,
      maxFileSizeBytes: options.maxFileSizeBytes
    )
    let scanTiming = try finishPhase(from: scanTimingStart, clock: clock)

    let runID = "run-\(UUID().uuidString)"
    let rewriter = SnapshotMigrationRewriter()
    let replacer = AtomicFileReplacer()

    var stagingStore: RunStagingStore?
    var keptStagingRoot: String?
    // Removal lives in a defer so an error unwinding the run cannot leak the staging
    // directory. Runs that decide to keep it (--keep-temp, or apply-failure recovery)
    // record that decision in keptStagingRoot before returning; --keep-temp also
    // preserves the directory when the run itself throws.
    defer {
      if let stagingStore, keptStagingRoot == nil, !options.keepTemp {
        stagingStore.remove()
      }
    }
    var hadMigrationFailures = false
    var hadApplyFailures = false
    var applyLockAcquisitionFailed = false
    var pendingApplies: [PendingApply] = []

    var candidateFiles = 0
    var candidateDeclarations = 0
    var migratedDeclarations = 0
    var skippedDeclarations = 0
    var failedDeclarations = 0
    var filesAttemptedApply = 0
    var filesApplied = 0
    var filesApplyFailed = 0
    var filesPreconditionFailed = 0
    var filesUnsafeNonRegular = 0
    var issueLines: [String] = []

    for relativePath in scan.unreadableFiles {
      issueLines.append(
        "\(relativePath):1 <unknown> file-unreadable file could not be read as UTF-8 text and was excluded from migration"
      )
    }
    for relativePath in scan.oversizeFiles {
      issueLines.append(
        "\(relativePath):1 <unknown> file-oversize file exceeds --max-file-size-bytes and was excluded from migration"
      )
    }

    let rewriteTimingStart = try startPhase(clock: clock)

    for file in scan.candidateFiles {
      let rewriteResult: RewriteResult
      do {
        rewriteResult = try rewriter.rewrite(source: file.contents)
      } catch {
        candidateFiles += 1
        hadMigrationFailures = true
        failedDeclarations += 1
        issueLines.append("\(file.relativePath):1 <unknown> syntax-parse-failed unable to rewrite declaration")
        continue
      }

      let declarations = rewriteResult.declarations

      // The scanner matches raw text, so `@SnapshotTest` inside a comment or string literal
      // still marks the file as a candidate. When parsing finds no legacy declarations and
      // the rewrite changes nothing, the file has no migratable surface: it stays counted
      // as scanned, contributes zero declarations, and must not register as a skip.
      guard !declarations.isEmpty || rewriteResult.changed else { continue }

      candidateFiles += 1
      candidateDeclarations += declarations.count

      let skippedInFile = declarations.filter { $0.resolution == .skipped }
      if !skippedInFile.isEmpty {
        // File-level applies stay all-or-nothing: one skipped declaration blocks the whole
        // file, but each declaration still gets its own count and reason line.
        skippedDeclarations += declarations.count
        for declaration in declarations {
          switch declaration.resolution {
          case .skipped:
            for reason in declaration.reasons {
              issueLines.append(
                "\(file.relativePath):\(reason.line) \(declaration.name) \(reason.code) \(reason.message)"
              )
            }
          case .migratable:
            let siblingNames = skippedInFile.map(\.name).joined(separator: ", ")
            issueLines.append(
              "\(file.relativePath):\(declaration.line) \(declaration.name) blocked-by-sibling-skip "
                + "declaration is migratable but was not applied because sibling declaration(s) "
                + "\(siblingNames) could not be migrated"
            )
          }
        }
        continue
      }

      guard rewriteResult.changed else {
        skippedDeclarations += declarations.count
        continue
      }

      // Every mode stages so dry-run enforces the same --max-staged-bytes cap an
      // apply run would hit; whether staging survives the run is decided at the end.
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
        failedDeclarations += max(1, declarations.count)
        issueLines.append(
          "\(file.relativePath):1 <unknown> \(Self.stagingIssueCode(for: error)) unable to stage rewritten output"
        )
        continue
      }

      pendingApplies.append(
        PendingApply(
          absolutePath: file.absolutePath,
          relativePath: file.relativePath,
          expectedHash: SHA256Hasher.hash(file.contents),
          rewrittenContents: rewriteResult.output,
          declarationCount: declarations.count
        )
      )
      migratedDeclarations += declarations.count
    }
    let rewriteTiming = try finishPhase(from: rewriteTimingStart, clock: clock)

    var applyTiming = MigrationPhaseTiming(wallSeconds: 0, cpuSeconds: 0)

    if options.mode == .apply && !hadMigrationFailures {
      let applyTimingStart = try startPhase(clock: clock)
      var applyLock: ApplyLock?
      do {
        applyLock = try ApplyLock.acquire(
          projectRoot: options.projectRoot,
          timeoutSeconds: options.applyLockTimeoutSeconds
        )
      } catch {
        hadApplyFailures = true
        applyLockAcquisitionFailed = true
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
            migratedDeclarations = max(0, migratedDeclarations - pendingApply.declarationCount)
            failedDeclarations += pendingApply.declarationCount
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
            }
            issueLines.append("\(pendingApply.relativePath):1 <unknown> \(reasonCode) apply failed")
          } catch {
            hadApplyFailures = true
            filesApplyFailed += 1
            migratedDeclarations = max(0, migratedDeclarations - pendingApply.declarationCount)
            failedDeclarations += pendingApply.declarationCount
            issueLines.append("\(pendingApply.relativePath):1 <unknown> atomic-write-failed apply failed")
          }
        }
      }
      applyTiming = try finishPhase(from: applyTimingStart, clock: clock)
    } else if options.mode == .apply {
      // Apply was requested but skipped because an earlier file failed to migrate/stage. The
      // staged rewrites never reached disk, so — mirroring the apply-lock-failure path (which
      // zeroes `migratedDeclarations` into `failedDeclarations`) — staged-but-unwritten work is
      // accounted as failed, not migrated. Without this, the report would claim
      // `migratedDeclarations > 0` with `filesApplied == 0`.
      failedDeclarations += migratedDeclarations
      migratedDeclarations = 0
    }

    // Staged copies are the only durable record of the rewritten output. Keep them
    // when the user asked (--keep-temp) or when an apply run failed, so the staged
    // rewrites remain available for inspection and manual recovery. Every other run
    // — dry-run included, success or failure — has its staging directory removed by
    // the defer declared alongside stagingStore.
    if let stagingStore {
      let keepForApplyRecovery = options.mode == .apply && (hadMigrationFailures || hadApplyFailures)
      if options.keepTemp || keepForApplyRecovery {
        keptStagingRoot = stagingStore.root
      }
    }

    let migrationPercentage: Int
    if candidateDeclarations == 0 {
      migrationPercentage = 100
    } else {
      migrationPercentage = Int((Double(migratedDeclarations) / Double(candidateDeclarations) * 100.0).rounded(.down))
    }
    let totalTiming = try finishPhase(from: totalTimingStart, clock: clock)

    let report = MigrationReport(
      reportSchemaVersion: 4,
      runID: runID,
      projectRoot: options.projectRoot,
      filesScanned: scan.filesScanned,
      candidateFiles: candidateFiles,
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
      filesUnreadable: scan.unreadableFiles.count,
      filesOversize: scan.oversizeFiles.count,
      applyLockAcquisitionFailed: applyLockAcquisitionFailed,
      issueLines: issueLines,
      timings: .init(
        total: totalTiming,
        scan: scanTiming,
        rewriteStage: rewriteTiming,
        apply: applyTiming
      )
    )

    // `hadMigrationFailures` is only ever set alongside a `failedDeclarations` increment (and
    // `failedDeclarations` is never decremented), so `resolveExitCode` already returns a
    // non-success code (`.migrationFailure` or `.applySafetyFailure`) whenever a migration failed.
    // No `.success`-to-`.migrationFailure` fallback is needed here.
    let exitCode = report.resolveExitCode(failOnSkips: options.failOnSkips)

    return MigrationRunOutcome(report: report, exitCode: exitCode, keptStagingRoot: keptStagingRoot)
  }
}

private struct ProcessCPUSnapshot {
  let seconds: Double

  static func current() throws -> ProcessCPUSnapshot {
    var usage = rusage()
    guard getrusage(RUSAGE_SELF, &usage) == 0 else {
      throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }

    let userSeconds = Double(usage.ru_utime.tv_sec) + Double(usage.ru_utime.tv_usec) / 1_000_000
    let systemSeconds = Double(usage.ru_stime.tv_sec) + Double(usage.ru_stime.tv_usec) / 1_000_000
    return ProcessCPUSnapshot(seconds: userSeconds + systemSeconds)
  }
}

private struct PhaseMeasurement {
  let wallStart: ContinuousClock.Instant
  let cpuStart: ProcessCPUSnapshot
}

private func startPhase(clock: ContinuousClock) throws -> PhaseMeasurement {
  PhaseMeasurement(wallStart: clock.now, cpuStart: try .current())
}

private func finishPhase(
  from start: PhaseMeasurement,
  clock: ContinuousClock
) throws -> MigrationPhaseTiming {
  let wallDuration = start.wallStart.duration(to: clock.now)
  let cpuEnd = try ProcessCPUSnapshot.current()
  let wallSeconds =
    Double(wallDuration.components.seconds)
    + Double(wallDuration.components.attoseconds) / 1_000_000_000_000_000_000

  return MigrationPhaseTiming(
    wallSeconds: wallSeconds,
    cpuSeconds: max(0, cpuEnd.seconds - start.cpuStart.seconds)
  )
}

private struct PendingApply {
  let absolutePath: String
  let relativePath: String
  let expectedHash: String
  let rewrittenContents: String
  /// Number of legacy declarations migrated by this file's rewrite, so apply failures
  /// move the exact per-declaration counts from migrated to failed.
  let declarationCount: Int
}
