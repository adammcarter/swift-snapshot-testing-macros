import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.BackgroundColor {

  @Suite
  @SnapshotSuite
  struct SwiftUI {

    @SnapshotTest
    func defaultBackground() -> some View {
      Text("\(#function) (clear)")
    }

    @SnapshotTest(
      .backgroundColor(.pink)
    )
    func defaultBackgroundOverridden() -> some View {
      Text("\(#function) (pink)")
    }

    @SnapshotTest(
      .backgroundColor(.blue)
    )
    func blue() -> some View {
      Text(#function)
    }

    @SnapshotTest(
      .backgroundColor(.clear)
    )
    func clear() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func viewBackgroundColor() -> some View {
      Text("\(#function) (green)")
        .background(.green)
    }

    // MARK: - Double background

    @SnapshotTest(
      .backgroundColor(.blue),
      .backgroundColor(.red)
    )
    func doubleBackground() -> some View {
      Text("\(#function) (red)")
    }
  }
}
