import Foundation
import SnapshotTesting
import Testing

extension Trait where Self == SnapshotTesting._SnapshotsTestTrait {
  /// A trait to use Point-Free style snapshot testing.
  ///
  /// This trait configures the test to look for snapshots in a `__Snapshots__` directory relative to the test file.
  ///
  /// Example:
  /// ```swift
  /// @SnapshotTest(.pointfreeSnapshots)
  /// func myView() -> some View { ... }
  /// ```
  public static var pointfreeSnapshots: Self { .snapshots }
}
