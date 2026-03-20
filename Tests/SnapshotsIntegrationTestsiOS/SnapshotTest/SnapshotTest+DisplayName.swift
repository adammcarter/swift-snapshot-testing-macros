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
        Text(#function)
      }

      @SnapshotTest("Some.name/with\\slashes")
      func fileSystemNameClashing() -> some View {
        Text(#function)
      }

      @SnapshotTest("")
      func emptyName() -> some View {
        Text(#function)
      }
    }
  }
}
