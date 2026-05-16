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
    let scan: ScanResult
    do {
      scan = try ProjectScanner().scan(
        projectRoot: options.projectRoot,
        maxFileSizeBytes: options.maxFileSizeBytes
      )
    } catch is ProjectScannerError {
      return .migrationFailure
    }

    return scan.candidateFiles.isEmpty ? .success : .migrationFailure
  }
}
