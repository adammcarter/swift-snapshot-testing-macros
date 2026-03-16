import Testing

/// A trait that can be applied to a single snapshot test.
///
/// Types conforming to this protocol can be used as arguments to the `@SnapshotTest` macro.
public protocol SnapshotTestTrait: SnapshotTrait, Testing.TestTrait {}
