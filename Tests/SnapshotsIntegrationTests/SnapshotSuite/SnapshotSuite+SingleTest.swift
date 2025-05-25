import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {
  @Suite
  @SnapshotSuite
  struct SingleTest {

    @SnapshotTest
    func singleTest() -> some View {
      Text("One test in a suite")
    }
  }
}
