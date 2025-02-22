import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {
  @Suite
  struct DisplayName {

    @Suite
    @SnapshotSuite
    struct TestDisplayNameTests {

      @SnapshotTest(
        "Named Suite"
      )
      func named() -> some View {
        Text("Named Test")
      }

      @SnapshotTest(
        ""
      )
      func emptyName() -> some View {
        Text("[empty display name]")
      }
    }
  }
}
