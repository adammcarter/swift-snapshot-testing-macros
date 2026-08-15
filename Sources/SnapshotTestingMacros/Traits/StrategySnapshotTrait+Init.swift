import Foundation
import Testing

extension Testing.Trait where Self == StrategySnapshotTrait {
  /// Sets the snapshot strategy.
  ///
  /// Only one `.strategy` may apply to a given `@Test` or `@Suite`: the strategy does not fan
  /// out into several snapshots the way `.theme` and `.sizes` do, so a second one on the same
  /// declaration fails the test rather than silently replacing the first. A suite-level default
  /// overridden by a test-level `.strategy` is unaffected.
  ///
  /// - Parameters:
  ///   - strategy: The strategy to use.
  ///   - sourceLocation: Where the trait was written. Defaults to the call site and should not
  ///     be passed explicitly; it is what lets a duplicate on one declaration be told apart
  ///     from a suite default that a test overrides.
  /// - Returns: A trait that applies the strategy.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.strategy(.image))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func strategy(
    _ strategy: StrategySnapshotTrait.Strategy,
    sourceLocation: SourceLocation = #_sourceLocation
  ) -> Self {
    Self(strategy: strategy, sourceLocation: sourceLocation)
  }
}
