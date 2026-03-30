#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding {

  struct UIKit {}
}

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(.red),
    .padding
  )
  struct BackgroundAndPadding {

    @SnapshotTest
    func backgroundAndPadding() -> UIView {
      makeLabel(#function)
    }
  }

  @MainActor
  @Suite
  @SnapshotSuite(
    .padding,
    .backgroundColor(.red)
  )
  struct PaddingAndBackground {

    @SnapshotTest
    func paddingAndBackground() -> UIView {
      makeLabel(#function)
    }
  }
}
#endif
