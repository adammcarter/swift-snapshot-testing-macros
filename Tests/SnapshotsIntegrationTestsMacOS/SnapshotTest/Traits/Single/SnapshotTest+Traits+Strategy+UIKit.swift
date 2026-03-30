#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.Strategy {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
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
