#if canImport(AppKit)
import AppKit

/// Renders an AppKit snapshot view hierarchy into an explicitly sized and scaled bitmap.
///
/// This is the AppKit mirror of the UIKit render path (pointfree's `prepareView`): the view is
/// re-hosted in an offscreen window at the request size, the theme's appearance is applied, a
/// full Auto Layout pass runs against the requested bounds, and the result is drawn at exactly
/// the request's display scale.
///
/// pointfree's `NSView`/`NSViewController` image strategies offer none of this: they poke
/// `frame.size` and `cacheDisplay` a windowless view with no layout pass, no appearance, and no
/// scale hook, leaving the pixel density to whatever backing scale the recording machine's
/// screen happens to have. That makes multi-size and fixed-size requests render stale layouts,
/// silently drops the documented `scale:` parameter, and produces references that differ
/// between Retina and non-Retina machines.
@MainActor
enum AppKitImageRenderer {
  static func render(
    viewController: SnapshotViewController,
    size: CGSize,
    displayScale: Double,
    appearance: NSAppearance,
    backgroundColor: NSColor?
  ) -> NSImage {
    let view = viewController.view
    let initialFrame = view.frame
    let initialAutoresizingMask = view.autoresizingMask

    let window = makeOffscreenWindow(size: size, appearance: appearance)
    view.appearance = appearance

    host(view, in: window, size: size)
    apply(backgroundColor, to: view)
    layOutHierarchy(of: window)

    let image = drawImage(of: view, size: size, displayScale: displayScale)

    view.removeFromSuperview()
    view.autoresizingMask = initialAutoresizingMask
    view.frame = initialFrame

    return image
  }

  private static func makeOffscreenWindow(size: CGSize, appearance: NSAppearance) -> NSWindow {
    let window = NSWindow(
      contentRect: .init(origin: .zero, size: size),
      styleMask: [.borderless],
      backing: .buffered,
      defer: true
    )

    window.isReleasedWhenClosed = false
    window.appearance = appearance
    // Pin the composition space: without this, `cacheDisplay` composites through the recording
    // machine's display profile before converting into the bitmap, so the rendered pixel values
    // (not just the pixel density) would differ between machines.
    window.colorSpace = .sRGB

    return window
  }

  /// Hosts the view in the window at the request size, detaching it from any previous
  /// superview (such as the transient container used to measure `.minimum` sizes).
  ///
  /// Mirrors the UIKit path's re-hosting: frame-based views fill the window through their
  /// autoresizing mask, while views already managed by Auto Layout are pinned to the window's
  /// content view so the layout pass solves them against the requested bounds.
  private static func host(_ view: NSView, in window: NSWindow, size: CGSize) {
    guard let contentView = window.contentView else {
      return
    }

    view.removeFromSuperview()
    contentView.addSubview(view)

    if view.translatesAutoresizingMaskIntoConstraints {
      view.frame = .init(origin: .zero, size: size)
      view.autoresizingMask = [.width, .height]
    }
    else {
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        view.topAnchor.constraint(equalTo: contentView.topAnchor),
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])
    }
  }

  /// Applies the decorator's background color under the view's themed effective appearance.
  ///
  /// Dynamic colors (e.g. `.windowBackgroundColor`) resolve against the appearance that is
  /// current when their `cgColor` is read, so the write must happen at render time under the
  /// applied theme for the light/dark fan-out to produce genuinely different backgrounds. This
  /// mirrors the UIKit path, where dynamic colors resolve against the render-time traits.
  private static func apply(_ backgroundColor: NSColor?, to view: NSView) {
    guard let backgroundColor else {
      return
    }

    view.effectiveAppearance.performAsCurrentDrawingAppearance {
      view.backgroundColor = backgroundColor
    }
  }

  private static func layOutHierarchy(of window: NSWindow) {
    guard let contentView = window.contentView else {
      return
    }

    contentView.needsLayout = true
    contentView.layoutSubtreeIfNeeded()
  }

  /// Draws the view into a bitmap whose pixel grid is the request size multiplied by the
  /// display scale. Mapping the view's point size onto that (scaled) pixel grid makes
  /// `cacheDisplay` render at exactly `displayScale` pixels per point, independent of the
  /// backing scale of whatever screen the tests run on.
  private static func drawImage(of view: NSView, size: CGSize, displayScale: Double) -> NSImage {
    let pixelsWide = Int((size.width * displayScale).rounded())
    let pixelsHigh = Int((size.height * displayScale).rounded())

    // Tagged sRGB before drawing so colors land in a fixed, machine-independent color space:
    // `bitmapImageRepForCachingDisplay` would inherit the recording screen's display profile.
    guard
      pixelsWide > 0, pixelsHigh > 0,
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelsWide,
        pixelsHigh: pixelsHigh,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )?
      .retagging(with: .sRGB)
    else {
      fatalError("View not renderable to image at size \(size) and scale \(displayScale)")
    }

    bitmap.size = size
    view.cacheDisplay(in: view.bounds, to: bitmap)

    let image = NSImage(size: size)
    image.addRepresentation(bitmap)

    return image
  }
}
#endif
