#if canImport(AppKit)
import AppKit
import SnapshotTesting

extension Snapshotting where Value == SnapshotViewController, Format == NSImage {
  @MainActor
  static func image(
    size: CGSize,
    appearance: NSAppearance,
    scale: Double
  ) -> Snapshotting {
    let base = Snapshotting<SnapshotViewController, NSImage>.image(size: size)

    return Snapshotting(
      pathExtension: base.pathExtension,
      diffing: base.diffing
    ) { viewController in
      Async { callback in
        let view = viewController.view
        let originalAppearance = view.appearance
        let originalFrame = view.frame

        let window = ScaledSnapshotWindow(size: size, scale: scale)
        window.appearance = appearance
        window.contentView?.appearance = appearance

        view.appearance = appearance
        view.frame = .init(origin: .zero, size: size)
        window.contentView?.addSubview(view)
        window.makeKey()

        base.snapshot(viewController)
          .run { image in
            view.appearance = originalAppearance
            view.removeFromSuperview()
            view.frame = originalFrame

            window.orderOut(nil)
            window.contentView = nil

            callback(image)
          }
      }
    }
  }
}

private final class ScaledSnapshotWindow: NSWindow {
  private let scale: CGFloat

  init(size: CGSize, scale: Double) {
    self.scale = scale

    super
      .init(
        contentRect: .init(origin: .zero, size: size),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
      )

    contentView = NSView(frame: .init(origin: .zero, size: size))
    isOpaque = false
    hasShadow = false
    backgroundColor = .clear
  }

  override var backingScaleFactor: CGFloat {
    scale
  }
}
#endif
