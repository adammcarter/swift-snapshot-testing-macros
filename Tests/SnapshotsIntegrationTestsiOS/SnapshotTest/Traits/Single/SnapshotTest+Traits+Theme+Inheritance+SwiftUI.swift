import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Theme.Inheritance {

  @Suite
  struct SwiftUI {

    // MARK: - Light

    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct Light {
      @SnapshotTest(
        .theme(.light)
      )
      func light() -> some View {
        snapshotText(".theme(.light)")
      }
    }

    // MARK: - Dark

    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct Dark {
      @SnapshotTest(
        .theme(.dark)
      )
      func dark() -> some View {
        snapshotText(".theme(.dark)")
      }
    }

    // MARK: - All

    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct All {
      @SnapshotTest(
        .theme(.all)
      )
      func all() -> some View {
        snapshotText(".theme(.all)")
      }
    }
  }
}
