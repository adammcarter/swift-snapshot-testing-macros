import Foundation
import Testing

/// The error thrown when more than one ``StrategySnapshotTrait`` is applied to a single test or
/// suite.
///
/// Surfaced from ``StrategySnapshotTrait/prepare(for:)``, so Swift Testing reports it before the
/// test body runs and nothing is ever rendered under an arbitrarily-chosen strategy.
struct ConflictingStrategySnapshotTraits: Error, CustomStringConvertible {
  let description: String
}

/// A trait that configures the snapshotting strategy.
///
/// Use this trait to switch between image-based comparison and recursive description comparison.
///
/// Only one `.strategy` trait may apply to a given declaration. Unlike ``ThemeSnapshotTrait`` and
/// ``SizesSnapshotTrait``, the strategy does not fan out into several snapshots, so a second
/// trait on the same `@Test` or `@Suite` is a contradiction rather than an addition — it fails
/// the declaration closed instead of letting the last one silently win. A suite-level `.strategy`
/// overridden by a test-level one is the ordinary trait hierarchy and stays supported.
public struct StrategySnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let strategy: Strategy

  /// Where `.strategy(...)` was written.
  ///
  /// Swift Testing hands a test's `prepare(for:)` the traits it inherits from its suites merged
  /// with its own, in that order, and offers no way to tell the two apart — a suite `.strategy`
  /// plus a test `.strategy` is indistinguishable by count from two on one declaration. The
  /// declaration site is what separates them: a trait written on this declaration cannot appear
  /// before the declaration's own attribute, while every inherited one must.
  let sourceLocation: SourceLocation

  @TaskLocal
  static var current = Strategy.image

  init(strategy: Strategy, sourceLocation: SourceLocation = #_sourceLocation) {
    self.strategy = strategy
    self.sourceLocation = sourceLocation
  }

  public var debugDescription: String {
    "strategy: \(strategy)"
  }

  /// Fails a test or suite closed when its own declaration carries more than one `.strategy`.
  ///
  /// The check lives here rather than in a macro because the trait list is not visible at
  /// expansion time: `.strategy` is applied to Apple's `@Test` and `@Suite` macros, which this
  /// package does not own, and `#expectSnapshot` is a freestanding expression macro that sees
  /// only its own arguments. This is the first point at which the applied traits exist at all.
  public func prepare(for test: Test) async throws {
    try Self.validateSingleApplication(in: test.traits, declaredAt: test.sourceLocation)
  }

  /// Throws when the declaration at `declaration` applies the strategy more than once, naming
  /// every strategy involved in declaration order.
  ///
  /// Two identical strategies conflict just as much as two differing ones: the rule is one
  /// trait, not one value.
  ///
  /// Traits whose own source location sits before `declaration`, or in another file, were
  /// written somewhere else — an enclosing suite, or a shared `let` in another file — and are
  /// not this declaration's to reject. That makes the check deliberately conservative: it never
  /// rejects the documented suite-default/test-override hierarchy, at the cost of missing a
  /// duplicate assembled out of traits defined in a different file.
  static func validateSingleApplication(
    in traits: [any Testing.Trait],
    declaredAt declaration: SourceLocation
  ) throws {
    let strategies =
      traits
      .compactMap(strategySnapshotTrait(in:))
      .filter { $0.isDeclared(at: declaration) }
      .map(\.strategy)

    guard strategies.count > 1 else {
      return
    }

    let names = strategies.map(\.debugDescription).joined(separator: ", ")

    throw ConflictingStrategySnapshotTraits(
      description: """
        Conflicting .strategy traits: \(names). Only one snapshot strategy may apply to a test \
        or suite, and .strategy does not fan out the way .theme and .sizes do — the last trait \
        applied would silently replace the others. Keep a single .strategy trait, or move the \
        others onto a different suite or test.
        """
    )
  }

  private func isDeclared(at declaration: SourceLocation) -> Bool {
    sourceLocation.fileID == declaration.fileID && sourceLocation.line >= declaration.line
  }

  /// Unwraps the boxes the legacy `@SnapshotSuite` / `@SnapshotTest` expansion applies traits
  /// through, so a boxed `.strategy` is counted alongside a natively-applied one.
  private static func strategySnapshotTrait(in trait: any Testing.Trait) -> StrategySnapshotTrait? {
    switch trait {
      case let strategyTrait as StrategySnapshotTrait:
        strategyTrait
      case let box as __TestScopingBox:
        strategySnapshotTrait(in: box.wrappedScoping)
      case let box as __TestTraitBox:
        strategySnapshotTrait(in: box.wrapped)
      case let box as __SuiteTraitBox:
        strategySnapshotTrait(in: box.wrapped)
      default:
        nil
    }
  }

  public func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await StrategySnapshotTrait.$current.withValue(strategy) {
      try await function()
    }
  }

  /// The type of snapshot strategy to use.
  public enum Strategy: Sendable, CustomDebugStringConvertible {
    /// Compare rendered images.
    case image
    /// Compare recursive view description (debug output).
    case recursiveDescription

    public var debugDescription: String {
      switch self {
        case .image: "image"
        case .recursiveDescription: "recursiveDescription"
      }
    }
  }
}
