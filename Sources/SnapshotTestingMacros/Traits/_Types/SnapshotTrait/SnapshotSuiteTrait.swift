import Testing

/// A trait that can be applied to a snapshot test suite.
///
/// Types conforming to this protocol can be used as arguments to the `@SnapshotSuite` macro.
public protocol SnapshotSuiteTrait: SnapshotTrait, Testing.SuiteTrait {}
