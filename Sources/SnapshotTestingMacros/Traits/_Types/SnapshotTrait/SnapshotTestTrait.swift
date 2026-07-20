import Testing

/// A trait that can be applied to a single snapshot test.
///
/// Types conforming to this protocol can be used as arguments to native `@Test`
/// declarations that contain `#expectSnapshot(...)` assertions.
public protocol SnapshotTestTrait: SnapshotTrait, Testing.TestTrait {}
