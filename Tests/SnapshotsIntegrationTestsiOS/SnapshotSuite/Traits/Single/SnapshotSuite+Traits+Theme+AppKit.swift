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
