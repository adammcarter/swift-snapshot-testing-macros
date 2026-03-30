import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite(.tags(.parameters))
  struct Parameters {

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct TestParametersTests {

      @SnapshotTest
      func missingParameters() -> some View {
        Text("@SnapshotTest")
      }

      @SnapshotTest()
      func emptyParameters() -> some View {
        Text("@SnapshotTest()")
      }
    }
  }
}
