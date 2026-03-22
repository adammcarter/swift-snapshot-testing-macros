#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.Sizes.Inheritance {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0)
  )
  struct AppKit {

    @SnapshotTest(
      .sizes(width: 320, height: 480, scale: 2.0)
    )
    func overridden() -> NSView {
      makeLabel("\(#function) (.fixed size)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> NSView {
      makeLabel("\(#function) (.minimum)")
    }
  }
}
#endif
