#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotTest.Traits.Theme {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct AppKit {

    // MARK: - Light

    @SnapshotTest(
      .theme(.light)
    )
    func testTraitThemeLightTests() -> NSView {
      makeLabel(".theme(.light)")
    }

    // MARK: - Dark

    @SnapshotTest(
      .theme(.dark)
    )
    func testTraitThemeDarkTests() -> NSView {
      makeLabel(".theme(.dark)")
    }

    // MARK: - All

    @SnapshotTest(
      .theme(.all)
    )
    func testTraitThemeAllTests() -> NSView {
      makeLabel(".theme(.all)")
    }
  }
}
#endif
