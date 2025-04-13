import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {
  @Suite
  @SnapshotSuite
  struct SwiftUI {

    @SnapshotTest()
    func swiftUiView() -> some View {
      Text("Some SwiftUI text")
    }
  }
}
