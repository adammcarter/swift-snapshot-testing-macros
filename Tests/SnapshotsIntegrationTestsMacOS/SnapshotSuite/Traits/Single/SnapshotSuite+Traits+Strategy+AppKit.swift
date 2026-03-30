#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.Strategy {
  @MainActor
  @Suite
  struct AppKit {

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.image)
    )
    struct ImageKind {

      @SnapshotTest
      func image() -> NSView {
        makeLabel(".image")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .strategy(.recursiveDescription)
    )
    struct RecursiveDescription {

      @SnapshotTest
      func recursiveDescription() -> NSView {
        makeLabel(".recursiveDescription")
      }
    }
  }
}
#endif
