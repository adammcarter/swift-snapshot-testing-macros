import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.BackgroundColor {
  @Suite
  @SnapshotSuite
  struct SwiftUI {

    @SnapshotTest
    func defaultBackground() -> some View {
      Text("Default background color")
    }

    @SnapshotTest(
      .backgroundColor(.blue)
    )
    func blue() -> some View {
      Text("SwiftUI .blue")
    }

    @SnapshotTest(
      .backgroundColor(.clear)
    )
    func clear() -> some View {
      Text("SwiftUI .clear")
    }

    @SnapshotTest
    func viewBackgroundColor() -> some View {
      Text("SwiftUI with explicit .background(.green)")
        .background(Color.green)
    }
  }
}
