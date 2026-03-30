#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotTest.Traits.Strategy {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct AppKit {

    @SnapshotTest(
      .strategy(.image)
    )
    func image() -> NSView {
      makeLabel(".image")
    }

    @SnapshotTest(
      .strategy(.recursiveDescription)
    )
    func recursiveDescription() -> NSView {
      makeLabel(".recursiveDescription")
    }
  }
}
#endif
