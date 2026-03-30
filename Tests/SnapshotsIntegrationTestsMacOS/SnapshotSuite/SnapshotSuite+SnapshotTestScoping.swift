import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  struct SnapshotTestScoping {

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .customValueTrait(value: "Suite")
    )
    struct Custom {

      @SnapshotTest
      func custom() -> some View {
        Text(CustomValueTrait.current)
      }
    }

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct Default {

      @SnapshotTest
      func withoutOverride() -> some View {
        Text(CustomValueTrait.current)
      }
    }
  }
}
