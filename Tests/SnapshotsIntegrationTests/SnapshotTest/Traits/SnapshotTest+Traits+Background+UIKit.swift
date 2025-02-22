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
      makeLabel("UIView with default background color")
    }

    @SnapshotTest(
      .backgroundColor(.blue)
    )
    func blue() -> UIView {
      makeLabel("UIKit .blue")
    }

    @SnapshotTest(
      .backgroundColor(.clear)
    )
    func clear() -> UIView {
      makeLabel("UIKit .clear")
    }

    @SnapshotTest
    func viewBackgroundColor() -> UIView {
      let label = makeLabel("UIKit with explicit backgroundColor = .green")
      label.backgroundColor = .green

      return label
    }
  }
}
#endif
