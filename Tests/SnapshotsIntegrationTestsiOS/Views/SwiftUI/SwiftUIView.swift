import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  @SnapshotSuite()
  struct SwiftUIView {

    @SnapshotTest()
    func swiftUiView() -> some View {
      snapshotText("Some SwiftUI text")
    }
  }
}
