#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.Theme.Inheritance {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .theme(.light)
  )
  struct AppKit {

    @SnapshotTest(
      .theme(.dark)
    )
    func overridden() -> NSView {
      makeLabel("\(#function) (.dark)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> NSView {
      makeLabel("\(#function) (.light)")
    }
  }
}
#endif
