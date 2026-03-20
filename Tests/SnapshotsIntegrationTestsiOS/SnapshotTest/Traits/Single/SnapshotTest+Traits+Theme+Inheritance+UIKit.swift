#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.Theme.Inheritance {

  @Suite
  struct UIKit {

    // MARK: - Light

    @MainActor
    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct Light {
      @SnapshotTest(
        .theme(.light)
      )
      func light() -> UIView {
        makeLabel(".theme(.light)")
      }
    }

    // MARK: - Dark

    @MainActor
    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct Dark {
      @SnapshotTest(
        .theme(.dark)
      )
      func dark() -> UIView {
        makeLabel(".theme(.dark)")
      }
    }

    // MARK: - All

    @MainActor
    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct All {
      @SnapshotTest(
        .theme(.all)
      )
      func all() -> UIView {
        makeLabel(".theme(.all)")
      }
    }
  }
}
#endif
