import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  @SnapshotSuite
  struct ManyTests {

    @SnapshotTest
    func testOne() -> some View {
      snapshotText("Test one of many in a suite")
    }

    @SnapshotTest
    func testTwo() -> some View {
      snapshotText("Test two of many in a suite")
    }

    @SnapshotTest
    func testThree() -> some View {
      snapshotText("Test three of many in a suite")
    }
  }
}
