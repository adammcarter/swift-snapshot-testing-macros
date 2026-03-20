#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Theme {

  @Suite
  struct UIKit {

    // MARK: - Theme Light

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.light)
    )
    struct Light {

      @SnapshotTest
      func light() -> UIView {
        makeLabel(".theme(.light)")
      }
    }

    // MARK: - Theme Dark

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.dark)
    )
    struct Dark {

      @SnapshotTest
      func dark() -> UIView {
        makeLabel(".theme(.dark)")
      }
    }

    // MARK: - Theme All

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.all)
    )
    struct All {

      @SnapshotTest
      func all() -> UIView {
        makeLabel(".theme(.all)")
      }
    }
  }
}
#endif
