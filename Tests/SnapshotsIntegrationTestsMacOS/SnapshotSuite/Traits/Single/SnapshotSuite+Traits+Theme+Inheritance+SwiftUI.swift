#if canImport(SwiftUI)
import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Theme.Inheritance {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .theme(.light)
  )
  struct SwiftUI {

    @SnapshotTest(
      .theme(.dark)
    )
    func overridden() -> some View {
      Text("\(#function) (.dark)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> some View {
      Text("\(#function) (.light)")
    }
  }
}
#endif
