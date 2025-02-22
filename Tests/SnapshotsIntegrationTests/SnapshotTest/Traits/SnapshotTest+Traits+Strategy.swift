import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits {
  @Suite
  @SnapshotSuite
  struct Strategy {

    @SnapshotTest(
      .strategy(.image)
    )
    func image() -> some View {
      Text(".image")
    }

    @SnapshotTest(
      .strategy(.recursiveDescription)
    )
    func recursiveDescription() -> some View {
      Text(".recursiveDescription")
    }
  }
}
