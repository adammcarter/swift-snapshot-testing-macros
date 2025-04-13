#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.Theme {
  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    // MARK: - Light

    @SnapshotTest(
      .theme(.light)
    )
    func testTraitThemeLightTests() -> UIView {
      makeLabel(".theme(.light)")
    }

    // MARK: - Dark

    @SnapshotTest(
      .theme(.dark)
    )
    func testTraitThemeDarkTests() -> UIView {
      makeLabel(".theme(.dark)")
    }

    // MARK: - All

    @SnapshotTest(
      .theme(.all)
    )
    func testTraitThemeAllTests() -> UIView {
      makeLabel(".theme(.all)")
    }
  }
}
#endif
