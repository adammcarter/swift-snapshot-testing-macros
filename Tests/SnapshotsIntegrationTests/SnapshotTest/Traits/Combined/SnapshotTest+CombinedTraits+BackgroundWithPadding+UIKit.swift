#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.CombinedTraits.BackgroundWithPadding {

  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    @SnapshotTest(
      .backgroundColor(.red),
      .padding
    )
    func backgroundAndPadding() -> UIView {
      makeLabel(#function)
    }

    @SnapshotTest(
      .padding,
      .backgroundColor(.red)
    )
    func paddingAndBackground() -> UIView {
      makeLabel(#function)
    }
  }
}
#endif
