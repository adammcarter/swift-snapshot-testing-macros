import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite(.tags(.parameters))
  struct Parameters {

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct Missing {

      @SnapshotTest
      func missingParameters() -> some View {
        Text("@SnapshotSuite")
      }
    }

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct Empty {

      @SnapshotTest
      func emptyParameters() -> some View {
        Text("@SnapshotSuite()")
      }
    }
  }
}
