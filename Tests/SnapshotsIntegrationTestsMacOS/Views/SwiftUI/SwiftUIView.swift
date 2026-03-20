import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct SwiftUIView {

    @SnapshotTest()
    func swiftUiView() -> some View {
      Text("Some SwiftUI text")
    }
  }
}
