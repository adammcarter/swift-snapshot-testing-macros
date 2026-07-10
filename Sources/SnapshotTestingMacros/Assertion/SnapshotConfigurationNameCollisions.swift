import Foundation

/// Process-global registry that detects distinct configuration values resolving to one
/// derived snapshot name.
///
/// Deriving names from `String(describing:)` folded through ``SnapshotNameNormalizer`` is
/// lossy — `"v1.0"` and `"v1 0"` both normalize to `"v1-0"` — so two cases of one
/// `@Test(arguments:)` can silently share a single reference file: one case is compared
/// against the other's reference, and re-recording overwrites it. Each derived name is
/// registered here with the raw description it was derived from; when the same call site
/// re-derives the same name from a *different* description, the collision is surfaced as a
/// test issue instead of corrupting references.
///
/// Keys combine the call site, the derived name, and the per-attempt occurrence index of that
/// pair:
/// - The call site scopes detection to one assertion, so unrelated tests never interact —
///   while still catching helpers invoked from several tests, whose artifacts genuinely
///   collide (they share `#function`, file, and line).
/// - The occurrence index (counted within the attempt's ``SnapshotExecutionContext``)
///   exempts loops that hit one call site several times within a single attempt: those are
///   already disambiguated by the display-name dedupe, and their Nth iterations align across
///   attempts for cross-case comparison.
/// - Re-registering the same description (repetitions, retries) is never a collision.
final class SnapshotConfigurationNameCollisions: @unchecked Sendable {
  static let shared = SnapshotConfigurationNameCollisions()

  private let lock = NSLock()
  private var valueDescriptionsByKey = [String: String]()

  /// Registers `valueDescription` as the preimage of `derivedName` at `callSite` and returns
  /// the previously registered, different description when another value already resolved
  /// the same derived name there — a collision.
  func conflictingValueDescription(
    callSite: String,
    derivedName: String,
    occurrence: Int,
    valueDescription: String
  ) -> String? {
    let key = "\(callSite)|\(occurrence)|\(derivedName)"

    return lock.withLock {
      guard let existing = valueDescriptionsByKey[key] else {
        valueDescriptionsByKey[key] = valueDescription
        return nil
      }

      return existing == valueDescription ? nil : existing
    }
  }
}
