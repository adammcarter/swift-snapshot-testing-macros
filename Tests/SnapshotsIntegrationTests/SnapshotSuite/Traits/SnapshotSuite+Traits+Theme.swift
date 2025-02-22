import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits {
  @Suite
  struct Theme {

    // MARK: - Theme Light

    @Suite
    @SnapshotSuite(
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
