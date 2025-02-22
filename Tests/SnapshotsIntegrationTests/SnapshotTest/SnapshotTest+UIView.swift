#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest {
  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKitView {

    @SnapshotTest()
    func uiView() -> UIView {
      let label = UILabel()
      label.text = "Some UILabel text"
      label.sizeToFit()

      return label
    }
  }
}
#endif
