import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {
  @Suite
  struct DisplayName {

    @Suite
    @SnapshotSuite("Named Suite")
    struct Named {

      @SnapshotTest
      func named() -> some View {
        Text("Named Suite")
      }
    }

    @Suite
    @SnapshotSuite("")
    struct Empty {

      @SnapshotTest
      func emptyName() -> some View {
        Text("[empty display name]")
      }
    }
  }
}
