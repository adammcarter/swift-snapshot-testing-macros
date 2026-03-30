import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct SingleTest {

    @SnapshotTest
    func singleTest() -> some View {
      Text("One test in a suite")
    }
  }
}
