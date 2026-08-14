import Foundation
import SnapshotTesting
import Testing

extension Trait where Self == SnapshotTesting._SnapshotsTestTrait {
  // Internal implementation detail:
  // The deprecated `@SnapshotSuite` macro applies this trait automatically
  // for generated suites, so native `@Suite` / `@Test` usage should not
  // need to use it directly.
  public static var pointfreeSnapshots: Self { .snapshots }
}
