import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Strategy {

  @Suite
  @SnapshotSuite
  struct SwiftUI {

    @SnapshotTest(
      .strategy(.image)
    )
    func image() -> some View {
      snapshotText(".image")
    }

    @SnapshotTest(
      .strategy(.recursiveDescription)
    )
    func recursiveDescription() -> some View {
      snapshotText(".recursiveDescription")
    }
  }
}
