#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Strategy {
  @Suite
  struct UIKit {

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.image)
    )
    struct ImageKind {

      @SnapshotTest
      func image() -> UIView {
        makeLabel(".image")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.recursiveDescription)
    )
    struct RecursiveDescription {

      @SnapshotTest
      func recursiveDescription() -> UIView {
        makeLabel(".recursiveDescription")
      }
    }
  }
}
#endif
