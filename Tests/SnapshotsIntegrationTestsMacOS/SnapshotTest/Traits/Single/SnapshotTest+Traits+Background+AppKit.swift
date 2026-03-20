#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotTest.Traits.BackgroundColor {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct AppKit {

    @SnapshotTest
    func defaultBackground() -> NSView {
      makeLabel("\(#function) (clear)")
    }

    @SnapshotTest(
      .backgroundColor(nsColor: .blue)
    )
    func blue() -> NSView {
      makeLabel(#function)
    }

    @SnapshotTest(
      .backgroundColor(nsColor: .clear)
    )
    func clear() -> NSView {
      makeLabel(#function)
    }

    @SnapshotTest
    func viewBackgroundColor() -> NSView {
      let label = makeLabel("\(#function) (green)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.green.cgColor

      return label
    }

    @SnapshotTest(
      .backgroundColor(nsColor: .orange)
    )
    func viewBackgroundColorOverridden() -> NSView {
      let label = makeLabel("\(#function) (green)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.green.cgColor

      return label
    }

    // MARK: - Double background

    @SnapshotTest(
      .backgroundColor(nsColor: .blue),
      .backgroundColor(nsColor: .red)
    )
    func doubleBackground() -> NSView {
      makeLabel("\(#function) (red)")
    }
  }
}
#endif
