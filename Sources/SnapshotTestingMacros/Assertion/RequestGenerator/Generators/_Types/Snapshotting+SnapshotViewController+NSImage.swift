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
        let runOnMain: (@escaping () -> Void) -> Void = { work in
          if Thread.isMainThread {
            work()
          } else {
            DispatchQueue.main.async(execute: work)
          }
        }

        runOnMain {
          let view = viewController.view
          let originalAppearance = view.appearance
          let originalFrame = view.frame
          let originalSuperview = view.superview
          let originalIndex = view.superview?.subviews.firstIndex(of: view)

          let window = ScaledSnapshotWindow(size: size, scale: scale)
          window.appearance = appearance
          window.contentView?.appearance = appearance

          view.appearance = appearance
          view.frame = .init(origin: .zero, size: size)
          window.contentView?.addSubview(view)
          view.layoutSubtreeIfNeeded()
          window.makeKeyAndOrderFront(nil)

          base.snapshot(viewController)
            .run { image in
              runOnMain {
                view.appearance = originalAppearance
                view.removeFromSuperview()
                if let originalSuperview, let originalIndex {
                  originalSuperview.subviews.insert(view, at: originalIndex)
                } else {
                  originalSuperview?.addSubview(view)
                }
                view.frame = originalFrame

                window.close()

                callback(image)
              }
            }
        }
      }
    }
  }
}

private final class ScaledSnapshotWindow: NSWindow {
  private let scale: CGFloat

  init(size: CGSize, scale: Double) {
    self.scale = CGFloat(scale)

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
    isReleasedWhenClosed = false
  }

  override var backingScaleFactor: CGFloat {
    scale
  }

  override var canBecomeKey: Bool {
    true
  }
}
#endif
