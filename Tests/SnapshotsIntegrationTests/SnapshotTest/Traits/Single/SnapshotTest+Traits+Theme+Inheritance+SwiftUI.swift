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
        Text(".theme(.light)")
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
        Text(".theme(.dark)")
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
        Text(".theme(.all)")
      }
    }
  }
}
