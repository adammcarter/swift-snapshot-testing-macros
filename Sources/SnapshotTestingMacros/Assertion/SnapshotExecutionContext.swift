import Foundation

private final class SnapshotExecutionContextNameState: @unchecked Sendable {
  let lock = NSLock()
  var usedNames = Set<String>()
  var referenceCounts = [String: Int]()
  var occurrenceCounts = [String: Int]()
}

final class SnapshotExecutionContext: Sendable {
  let baseName: String

  /// A stable per-case discriminator for the parameterized `@Test(arguments:)` case that owns
  /// this attempt, or `nil` for a non-parameterized test. When present, it is folded into the
  /// unnamed base name so distinct cases resolve distinct reference files (see
  /// ``SnapshotCaseDiscriminator``).
  let caseDiscriminator: String?

  private let nameState = SnapshotExecutionContextNameState()

  init(function: StaticString, caseDiscriminator: String? = nil) {
    let raw = String(describing: function)
    let candidate = raw.split(separator: "(").first.map(String.init) ?? raw
    self.baseName = candidate.isEmpty ? "snapshot" : candidate
    self.caseDiscriminator = caseDiscriminator
  }

  /// Resolves the display name for one assertion, deduplicating repeats within this attempt.
  ///
  /// An unnamed assertion (`override == nil`) folds in the attempt's ``caseDiscriminator`` when
  /// one is present and `disambiguatesUnnamedCase` is `true`, so each parameterized case gets a
  /// distinct reference name. `disambiguatesUnnamedCase` is `false` on the
  /// `argument:`/configuration path, whose configuration name already distinguishes the case —
  /// folding there would needlessly churn those references. A named assertion is the user's
  /// deliberate choice and is never rewritten.
  func resolvedAssertionName(
    named override: String?,
    disambiguatesUnnamedCase: Bool = true
  ) -> String {
    let requestedName: String
    if let override {
      requestedName = override
    }
    else if disambiguatesUnnamedCase, let caseDiscriminator {
      requestedName = "\(baseName)-\(caseDiscriminator)"
    }
    else {
      requestedName = baseName
    }

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

  /// Counts how many times `key` has occurred within this attempt, starting at `1`.
  ///
  /// Used by the derived-configuration-name collision guard
  /// (``SnapshotConfigurationNameCollisions``) to tell "the same call site executed again in
  /// this attempt" (a loop — disambiguated by display-name dedupe, never a collision) apart
  /// from "the same call site executed in another attempt" (a parameterized case — a
  /// collision when the derived name matches but the value doesn't).
  func nextOccurrenceIndex(forKey key: String) -> Int {
    nameState.lock.withLock {
      let next = (nameState.occurrenceCounts[key] ?? 0) + 1
      nameState.occurrenceCounts[key] = next
      return next
    }
  }
}
