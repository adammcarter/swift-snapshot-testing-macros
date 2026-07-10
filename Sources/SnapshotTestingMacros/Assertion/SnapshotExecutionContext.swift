import Foundation

private final class SnapshotExecutionContextNameState: @unchecked Sendable {
  let lock = NSLock()
  var usedNames = Set<String>()
  var referenceCounts = [String: Int]()
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
      if nameState.usedNames.insert(Self.dedupKey(for: requestedName)).inserted {
        return requestedName
      }

      var suffix = 2
      while true {
        let candidate = "\(requestedName)-\(suffix)"
        if nameState.usedNames.insert(Self.dedupKey(for: candidate)).inserted {
          return candidate
        }

        suffix += 1
      }
    }
  }

  /// The form of `name` that uniqueness must be enforced on: reference files are written with
  /// every non-word character collapsed to `-` (`SnapshotNameNormalizer` here, pointfree's
  /// `sanitizePathComponent` downstream), so raw names that sanitize identically — e.g.
  /// "menu view" vs "menu-view" — would silently share one reference file if deduped raw.
  /// Slash-separated path segments are normalized individually and keep their `/` because
  /// they resolve to distinct subdirectories, not to one filename component.
  private static func dedupKey(for name: String) -> String {
    name
      .split(separator: "/", omittingEmptySubsequences: true)
      .map { SnapshotNameNormalizer.folderComponent(from: String($0)) }
      .joined(separator: "/")
  }

  static func resolvedAssertionName(named override: String?, baseName: String) -> String {
    override ?? baseName
  }

  /// Returns the next `.N` reference-file identifier for `key`, counting within this context.
  ///
  /// This is the per-attempt equivalent of the counter pointfree's `.snapshots` trait binds
  /// per test: the first reference for a key is `1`, subsequent same-key references within the
  /// attempt count up deterministically in assertion order, and a new attempt — which owns a
  /// fresh context — restarts at `1`, so repetitions and retries resolve the same reference
  /// files again.
  func nextReferenceIdentifier(forKey key: String) -> String {
    nameState.lock.withLock {
      let next = (nameState.referenceCounts[key] ?? 0) + 1
      nameState.referenceCounts[key] = next
      return String(next)
    }
  }
}
