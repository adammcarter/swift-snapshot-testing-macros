import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.BackgroundColor {
  @Suite
  struct SwiftUI {

    @Suite
    @SnapshotSuite
    struct Default {

      @SnapshotTest
      func defaultBackground() -> some View {
        Text("Default background color")
      }
    }

    @Suite
    @SnapshotSuite(
      .backgroundColor(.blue)
    )
    struct Blue {

      @SnapshotTest
      func blue() -> some View {
        Text("SwiftUI .blue")
      }
    }

    @Suite
    @SnapshotSuite(
      .backgroundColor(.clear)
    )
    struct Clear {

      @SnapshotTest
      func clear() -> some View {
        Text("SwiftUI .clear")
      }
    }

    @Suite
    @SnapshotSuite
    struct ViewBackgroundColor {

      @SnapshotTest
      func viewBackgroundColor() -> some View {
        Text("SwiftUI with explicit .background(.green)")
          .background(Color.green)
      }
    }

    @Suite
    @SnapshotSuite(
      .backgroundColor(.gray)
    )
    struct Inheritance {

      @SnapshotTest(
        .backgroundColor(.orange)
      )
      func overridden() -> some View {
        Text("This should be .orange")
      }

      @SnapshotTest
      func inheritedFromSuite() -> some View {
        Text("This should be .gray")
      }
    }
  }
}
