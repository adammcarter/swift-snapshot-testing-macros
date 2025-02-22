import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {
  @Suite
  struct Parameters {

    @Suite
    @SnapshotSuite
    struct Missing {

      @SnapshotTest
      func missingParameters() -> some View {
        Text("@SnapshotSuite")
      }
    }

    @Suite
    @SnapshotSuite
    struct Empty {

      @SnapshotTest
      func emptyParameters() -> some View {
        Text("@SnapshotSuite()")
      }
    }
  }
}
