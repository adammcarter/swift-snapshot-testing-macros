import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct DisplayName {

    @Suite
    @SnapshotSuite
    struct TestDisplayNameTests {

      @SnapshotTest("Named Test")
      func named() -> some View {
        snapshotText(#function)
      }

      @SnapshotTest("Some.name/with\\slashes")
      func fileSystemNameClashing() -> some View {
        snapshotText(#function)
      }

      @SnapshotTest("")
      func emptyName() -> some View {
        snapshotText(#function)
      }
    }
  }
}
