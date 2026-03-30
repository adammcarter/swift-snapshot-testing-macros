import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite(.tags(.parameters))
  struct Parameters {

    @Suite
    @SnapshotSuite
    struct TestParametersTests {

      @SnapshotTest
      func missingParameters() -> some View {
        snapshotText("@SnapshotTest")
      }

      @SnapshotTest()
      func emptyParameters() -> some View {
        snapshotText("@SnapshotTest()")
      }
    }
  }
}
