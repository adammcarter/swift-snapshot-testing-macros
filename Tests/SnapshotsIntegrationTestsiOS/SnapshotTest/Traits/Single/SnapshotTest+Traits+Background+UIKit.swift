#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.BackgroundColor {

  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    @SnapshotTest
    func defaultBackground() -> UIView {
      makeLabel("\(#function) (clear)")
    }

    @SnapshotTest(
      .backgroundColor(uiColor: .blue)
    )
    func blue() -> UIView {
      makeLabel(#function)
    }

    @SnapshotTest(
      .backgroundColor(uiColor: .clear)
    )
    func clear() -> UIView {
      makeLabel(#function)
    }

    @SnapshotTest
    func viewBackgroundColor() -> UIView {
      let label = makeLabel("\(#function) (green)")
      label.backgroundColor = .green

      return label
    }

    @SnapshotTest(
      .backgroundColor(uiColor: .orange)
    )
    func viewBackgroundColorOverridden() -> UIView {
      let label = makeLabel("\(#function) (green)")
      label.backgroundColor = .green

      return label
    }

    // MARK: - Double background

    @SnapshotTest(
      .backgroundColor(uiColor: .blue),
      .backgroundColor(uiColor: .red)
    )
    func doubleBackground() -> UIView {
      makeLabel("\(#function) (red)")
    }
  }
}
#endif
