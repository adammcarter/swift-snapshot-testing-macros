import Foundation

private final class SnapshotExecutionContextNameState: @unchecked Sendable {
  let lock = NSLock()
  var usedNames = Set<String>()
}

final class SnapshotExecutionContext: Sendable {
  let baseName: String
  private let nameState = SnapshotExecutionContextNameState()

  init(function: StaticString) {
    let raw = String(describing: function)
    let candidate = raw.split(separator: "(").first.map(String.init) ?? raw
    self.baseName = candidate.isEmpty ? "snapshot" : candidate
  }

  func resolvedAssertionName(named override: String?) -> String {
    let requestedName = Self.resolvedAssertionName(named: override, baseName: baseName)
    return nameState.lock.withLock {
      if nameState.usedNames.insert(requestedName).inserted {
        return requestedName
      }

      var suffix = 2
      while true {
        let candidate = "\(requestedName)-\(suffix)"
        if nameState.usedNames.insert(candidate).inserted {
          return candidate
        }

        suffix += 1
      }
    }
  }

  static func resolvedAssertionName(named override: String?, baseName: String) -> String {
    override ?? baseName
  }
}
