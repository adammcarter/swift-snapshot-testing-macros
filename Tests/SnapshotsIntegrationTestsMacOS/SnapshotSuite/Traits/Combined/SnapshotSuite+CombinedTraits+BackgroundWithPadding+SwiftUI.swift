import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding {

  struct SwiftUI {}
}

extension SnapshotSuite.CombinedTraits.BackgroundWithPadding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
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
    .sizes(.minimum, scale: 2.0),
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
