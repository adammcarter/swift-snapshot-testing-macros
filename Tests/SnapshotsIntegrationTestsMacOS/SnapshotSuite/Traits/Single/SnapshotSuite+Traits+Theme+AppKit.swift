#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.Theme {

  @Suite
  struct AppKit {

    // MARK: - Theme Light

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.light)
    )
    struct Light {

      @SnapshotTest
      func light() -> NSView {
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
      func dark() -> NSView {
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
      func all() -> NSView {
        makeLabel(".theme(.all)")
      }
    }
  }
}
#endif
