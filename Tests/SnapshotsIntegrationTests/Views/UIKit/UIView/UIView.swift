#if canImport(UIKit)
import SnapshotSupport
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest {

  @MainActor
  @Suite
  @SnapshotSuite
  struct _UIView {  // swiftlint:disable:this type_name

    @SnapshotTest
    func uiView() -> UIView {
      makeLabel("Some UILabel text")
    }

    @SnapshotTest
    func clearBackground() -> UIView {
      makeLabel("UILabel with clear background")
    }
  }
}
#endif
