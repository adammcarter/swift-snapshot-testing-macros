import Testing

/// A trait that can be applied to a snapshot test suite.
///
/// Types conforming to this protocol can be used as arguments to native `@Suite`
/// declarations that contain `#expectSnapshot(...)` assertions.
public protocol SnapshotSuiteTrait: SnapshotTrait, Testing.SuiteTrait {}

extension SnapshotSuiteTrait {
  /// Snapshot suite traits apply recursively so Swift Testing invokes their scope once per
  /// descendant test case (`testCase != nil`) instead of once around the whole suite.
  ///
  /// Per-case scoping is what lets ``SnapshotTestScoping`` bind a fresh per-attempt token for
  /// every test-case execution; a single suite-level scope would share one token — and one
  /// execution context — across every test in the suite, leaking artifact names between tests.
  public var isRecursive: Bool { true }
}
