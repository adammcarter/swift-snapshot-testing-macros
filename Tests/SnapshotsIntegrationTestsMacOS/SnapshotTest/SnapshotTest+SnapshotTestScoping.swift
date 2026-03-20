import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct SnapshotTestScoping {

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct Custom {

      @SnapshotTest(
        .customValueTrait(value: "Test")
      )
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
