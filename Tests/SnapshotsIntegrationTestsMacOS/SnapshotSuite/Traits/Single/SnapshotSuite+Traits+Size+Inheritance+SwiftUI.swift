#if canImport(SwiftUI)
import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Sizes.Inheritance {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0)
  )
  struct SwiftUI {

    @SnapshotTest(
      .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
    )
    func overridden() -> some View {
      Text("\(#function) (.iPhoneX, .widthAndHeight)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> some View {
      Text("\(#function) (.minimum)")
    }
  }
}
#endif
