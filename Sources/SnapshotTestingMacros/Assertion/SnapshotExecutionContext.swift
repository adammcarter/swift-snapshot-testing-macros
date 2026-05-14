final class SnapshotExecutionContext: Sendable {
  let baseName: String

  init(function: StaticString) {
    let raw = String(describing: function)
    let candidate = raw.split(separator: "(").first.map(String.init) ?? raw
    self.baseName = candidate.isEmpty ? "snapshot" : candidate
  }
}
