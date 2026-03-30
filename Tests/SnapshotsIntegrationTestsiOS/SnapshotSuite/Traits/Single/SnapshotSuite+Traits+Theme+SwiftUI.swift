import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Theme {

  @Suite
  struct SwiftUI {

    // MARK: - Theme Light

    @Suite
    @SnapshotSuite(
      .theme(.light)
    )
    struct Light {

      @SnapshotTest
      func light() -> some View {
        snapshotText(".theme(.light)")
      }
    }

    // MARK: - Theme Dark

    @Suite
    @SnapshotSuite(
      .theme(.dark)
    )
    struct Dark {

      @SnapshotTest
      func dark() -> some View {
        snapshotText(".theme(.dark)")
      }
    }

    // MARK: - Theme All

    @Suite
    @SnapshotSuite(
      .theme(.all)
    )
    struct All {

      @SnapshotTest
      func all() -> some View {
        snapshotText(".theme(.all)")
      }
    }
  }
}
