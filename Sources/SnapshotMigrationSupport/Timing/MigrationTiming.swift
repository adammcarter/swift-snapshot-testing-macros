public struct MigrationPhaseTiming: Codable, Equatable, Sendable {
  public let wallSeconds: Double
  public let cpuSeconds: Double

  public init(wallSeconds: Double, cpuSeconds: Double) {
    self.wallSeconds = wallSeconds
    self.cpuSeconds = cpuSeconds
  }
}

public struct MigrationTimings: Codable, Equatable, Sendable {
  public let total: MigrationPhaseTiming
  public let scan: MigrationPhaseTiming
  public let rewriteStage: MigrationPhaseTiming
  public let apply: MigrationPhaseTiming

  public init(
    total: MigrationPhaseTiming,
    scan: MigrationPhaseTiming,
    rewriteStage: MigrationPhaseTiming,
    apply: MigrationPhaseTiming
  ) {
    self.total = total
    self.scan = scan
    self.rewriteStage = rewriteStage
    self.apply = apply
  }

  public static let zero = MigrationTimings(
    total: .init(wallSeconds: 0, cpuSeconds: 0),
    scan: .init(wallSeconds: 0, cpuSeconds: 0),
    rewriteStage: .init(wallSeconds: 0, cpuSeconds: 0),
    apply: .init(wallSeconds: 0, cpuSeconds: 0)
  )
}
