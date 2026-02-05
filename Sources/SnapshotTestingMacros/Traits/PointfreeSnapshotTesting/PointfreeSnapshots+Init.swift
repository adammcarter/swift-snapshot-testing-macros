import Foundation
import SnapshotTesting
import Testing

extension Trait where Self == SnapshotTesting._SnapshotsTestTrait {
  public static var pointfreeSnapshots: Self { .snapshots }
}
