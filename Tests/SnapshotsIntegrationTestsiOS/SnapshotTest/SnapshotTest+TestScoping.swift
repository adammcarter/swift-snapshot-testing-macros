import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct TestScoping {

    @Suite
    @SnapshotSuite
    struct Custom {

      @SnapshotTest(
        /// Use an existing `TestScoping` trait with `@SnapshotTest`
        .testScopingTrait(value: "TestScoping")
      )
      func testScoping() -> some View {
        Text(MyExampleTrait.current)
      }
    }
  }
}
