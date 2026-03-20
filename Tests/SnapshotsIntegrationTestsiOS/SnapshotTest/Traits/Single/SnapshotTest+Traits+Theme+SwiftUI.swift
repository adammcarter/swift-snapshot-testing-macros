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
      Text(".theme(.light)")
    }

    // MARK: - Dark

    @SnapshotTest(
      .theme(.dark)
    )
    func testTraitThemeDarkTests() -> some View {
      Text(".theme(.dark)")
    }

    // MARK: - All

    @SnapshotTest(
      .theme(.all)
    )
    func testTraitThemeAllTests() -> some View {
      Text(".theme(.all)")
    }
  }
}
