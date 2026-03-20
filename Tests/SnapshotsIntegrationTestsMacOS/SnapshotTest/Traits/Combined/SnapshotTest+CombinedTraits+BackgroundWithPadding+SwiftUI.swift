import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.CombinedTraits.BackgroundWithPadding {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct SwiftUI {

    @SnapshotTest(
      .backgroundColor(.red),
      .padding
    )
    func backgroundAndPadding() -> some View {
      Text(#function)
    }

    @SnapshotTest(
      .padding,
      .backgroundColor(.red)
    )
    func paddingAndBackground() -> some View {
      Text(#function)
    }
  }
}
