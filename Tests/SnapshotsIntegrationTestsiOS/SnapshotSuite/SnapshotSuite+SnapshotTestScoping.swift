import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  struct SnapshotTestScoping {

    @Suite
    @SnapshotSuite(
      .customValueTrait(value: "Suite")
    )
    struct Custom {

      @SnapshotTest
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
