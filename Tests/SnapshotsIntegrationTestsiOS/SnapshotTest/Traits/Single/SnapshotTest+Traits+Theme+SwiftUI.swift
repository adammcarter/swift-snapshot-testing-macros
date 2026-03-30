import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Theme {

  @Suite
  @SnapshotSuite
  struct SwiftUI {

    // MARK: - Light

    @SnapshotTest(
      .theme(.light)
    )
    func testTraitThemeLightTests() -> some View {
      snapshotText(".theme(.light)")
    }

    // MARK: - Dark

    @SnapshotTest(
      .theme(.dark)
    )
    func testTraitThemeDarkTests() -> some View {
      snapshotText(".theme(.dark)")
    }

    // MARK: - All

    @SnapshotTest(
      .theme(.all)
    )
    func testTraitThemeAllTests() -> some View {
      snapshotText(".theme(.all)")
    }
  }
}
