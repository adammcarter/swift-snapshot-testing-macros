import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {
  @Suite
  struct Parameters {

    @Suite
    @SnapshotSuite
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
