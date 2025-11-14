import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.CombinedTraits.BackgroundWithPadding {

  @MainActor
  @Suite
  @SnapshotSuite
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
