import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Theme {

  @Suite
  struct SwiftUI {

    // MARK: - Theme Light

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.light)
    )
    struct Light {

      @SnapshotTest
      func light() -> some View {
        Text(".theme(.light)")
      }
    }

    // MARK: - Theme Dark

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.dark)
    )
    struct Dark {

      @SnapshotTest
      func dark() -> some View {
        Text(".theme(.dark)")
      }
    }

    // MARK: - Theme All

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .theme(.all)
    )
    struct All {

      @SnapshotTest
      func all() -> some View {
        Text(".theme(.all)")
      }
    }
  }
}
