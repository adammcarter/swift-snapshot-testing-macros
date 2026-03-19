#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotTest.Traits.Theme.Inheritance {

  @Suite
  struct AppKit {

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
      func light() -> NSView {
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
      func dark() -> NSView {
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
      func all() -> NSView {
        makeLabel(".theme(.all)")
      }
    }
  }
}
#endif
