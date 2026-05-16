import Foundation

public struct JSONReporter {
  public init() {}

  public func write(report: MigrationReport, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(report)
    try data.write(to: URL(fileURLWithPath: path))
  }
}
