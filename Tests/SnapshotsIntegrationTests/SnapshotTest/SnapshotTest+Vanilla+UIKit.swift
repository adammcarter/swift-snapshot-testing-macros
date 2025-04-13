#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest {
  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    @SnapshotTest()
    func uiView() -> UIView {
      makeLabel("Some UILabel text")
    }

    @SnapshotTest()
    func clearBackground() -> UIView {
      let label = UILabel()
      label.text = "UILabel with clear background"
      label.sizeToFit()

      return label
    }
  }
}
#endif
