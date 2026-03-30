import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Strategy {
  @Suite
  struct SwiftUI {

    @Suite
    @SnapshotSuite(
      .strategy(.image)
    )
    struct ImageKind {

      @SnapshotTest
      func image() -> some View {
        snapshotText(".image")
      }
    }

    @Suite
    @SnapshotSuite(
      .strategy(.recursiveDescription)
    )
    struct RecursiveDescription {

      @SnapshotTest
      func recursiveDescription() -> some View {
        snapshotText(".recursiveDescription")
      }
    }
  }
}
