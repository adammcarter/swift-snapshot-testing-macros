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
        snapshotText(#function)
      }
    }

    @Suite
    @SnapshotSuite("Some.name/with\\slashes")
    struct FileSystemNameClashing {

      @SnapshotTest
      func fileSystemNameClashing() -> some View {
        snapshotText(#function)
      }
    }

    @Suite
    @SnapshotSuite("")
    struct Empty {

      @SnapshotTest
      func emptyName() -> some View {
        snapshotText(#function)
      }
    }
  }
}
