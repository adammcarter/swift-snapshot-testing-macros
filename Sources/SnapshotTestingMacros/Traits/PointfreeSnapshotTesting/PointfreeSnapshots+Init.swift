import Foundation
import SnapshotTesting
import Testing

extension Trait where Self == SnapshotTesting._SnapshotsTestTrait {
  // Internal implementation detail:
  // `@SnapshotSuite` applies this trait automatically for generated suites,
  // so it does not need to be used directly.
  public static var pointfreeSnapshots: Self { .snapshots }
}
