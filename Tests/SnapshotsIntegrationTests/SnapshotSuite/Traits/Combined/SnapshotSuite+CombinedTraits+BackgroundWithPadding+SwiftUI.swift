import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding {

  struct SwiftUI {}
}

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .backgroundColor(.red),
    .padding
  )
  struct BackgroundAndPadding {

    @SnapshotTest
    func backgroundAndPadding() -> some View {
      Text(#function)
    }
  }

  @Suite
  @SnapshotSuite(
    .padding,
    .backgroundColor(.red)
  )
  struct PaddingAndBackground {

    @SnapshotTest
    func paddingAndBackground() -> some View {
      Text(#function)
    }
  }
}
