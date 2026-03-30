import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Strategy {

  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct SwiftUI {

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
