#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.BackgroundColor {
  @Suite
  struct UIKit {

    @MainActor
    @Suite
    @SnapshotSuite
    struct Default {

      @SnapshotTest
      func defaultBackground() -> UIView {
        makeLabel("UIView with default background color")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .backgroundColor(.blue)
    )
    struct Blue {

      @SnapshotTest
      func blue() -> UIView {
        makeLabel("UIKit .blue")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .backgroundColor(.clear)
    )
    struct Clear {

      @SnapshotTest
      func clear() -> UIView {
        makeLabel("UIKit .clear")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite
    struct ViewBackgroundColor {

      @SnapshotTest
      func viewBackgroundColor() -> UIView {
        let label = makeLabel("UIKit with explicit backgroundColor = .green")
        label.backgroundColor = .green

        return label
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .backgroundColor(.gray)
    )
    struct Inheritance {

      @SnapshotTest(
        .backgroundColor(.orange)
      )
      func overridden() -> UIView {
        makeLabel("This should be .orange")
      }

      @SnapshotTest
      func inheritedFromSuite() -> UIView {
        makeLabel("This should be .gray")
      }
    }
  }
}
#endif
