#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.Strategy {

  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    @SnapshotTest(
      .strategy(.image)
    )
    func image() -> UIView {
      makeLabel(".image")
    }

    @SnapshotTest(
      .strategy(.recursiveDescription)
    )
    func recursiveDescription() -> UIView {
      makeLabel(".recursiveDescription")
    }
  }
}
#endif
