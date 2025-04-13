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
