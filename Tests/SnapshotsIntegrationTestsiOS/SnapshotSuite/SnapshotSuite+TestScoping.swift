import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  struct TestScoping {

    @Suite
    @SnapshotSuite(
      /// Use an existing `TestScoping` trait with `@SnapshotSuite`
      .testScopingTrait(value: "TestScoping")
    )
    struct Custom {

      @SnapshotTest
      func testScoping() -> some View {
        Text(MyExampleTrait.current)
      }
    }
  }
}
