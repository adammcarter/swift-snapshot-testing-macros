import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Strategy {
  @Suite
  struct SwiftUI {

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.image)
    )
    struct ImageKind {

      @SnapshotTest
      func image() -> some View {
        Text(".image")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.recursiveDescription)
    )
    struct RecursiveDescription {

      @SnapshotTest
      func recursiveDescription() -> some View {
        Text(".recursiveDescription")
      }
    }
  }
}
