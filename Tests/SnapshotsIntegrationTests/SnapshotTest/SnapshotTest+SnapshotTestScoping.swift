import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct SnapshotTestScoping {

    @Suite
    @SnapshotSuite
    struct Custom {

      @SnapshotTest(
        .customValueTrait(value: "Test")
      )
      func custom() -> some View {
        Text(CustomValueTrait.current)
      }
    }

    @Suite
    @SnapshotSuite
    struct Default {

      @SnapshotTest
      func withoutOverride() -> some View {
        Text(CustomValueTrait.current)
      }
    }
  }
}
