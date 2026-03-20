import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct ManyTests {

    @SnapshotTest
    func testOne() -> some View {
      Text("Test one of many in a suite")
    }

    @SnapshotTest
    func testTwo() -> some View {
      Text("Test two of many in a suite")
    }

    @SnapshotTest
    func testThree() -> some View {
      Text("Test three of many in a suite")
    }
  }
}
