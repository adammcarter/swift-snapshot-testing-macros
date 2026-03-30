import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.BackgroundColor {

  @Suite
  @SnapshotSuite
  struct SwiftUI {

    @SnapshotTest
    func defaultBackground() -> some View {
      snapshotText("\(#function) (clear)")
    }

    @SnapshotTest(
      .backgroundColor(.pink)
    )
    func defaultBackgroundOverridden() -> some View {
      snapshotText("\(#function) (pink)")
    }

    @SnapshotTest(
      .backgroundColor(.blue)
    )
    func blue() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest(
      .backgroundColor(.clear)
    )
    func clear() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func viewBackgroundColor() -> some View {
      snapshotText("\(#function) (green)")
        .background(.green)
    }

    // MARK: - Double background

    @SnapshotTest(
      .backgroundColor(.blue),
      .backgroundColor(.red)
    )
    func doubleBackground() -> some View {
      snapshotText("\(#function) (red)")
    }
  }
}
