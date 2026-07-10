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
    // The render overrides the caller's appearance (to the theme) and forces layer-backing on
    // (so `apply(_:to:)` can paint the decorator background); capture both so the snapshot does
    // not permanently mutate a view the caller may reuse in a real layout.
    let initialAppearance = view.appearance
    let initialWantsLayer = view.wantsLayer

    let window = makeOffscreenWindow(size: size, appearance: appearance)
    view.appearance = appearance

    host(view, in: window, size: size)
    apply(backgroundColor, to: view)
    layOutHierarchy(of: window)

    let image = drawImage(of: view, size: size, displayScale: displayScale)

    view.removeFromSuperview()
    view.autoresizingMask = initialAutoresizingMask
    view.frame = initialFrame
    view.appearance = initialAppearance
    // Restoring `wantsLayer` to its original `false` also discards the layer the render created
    // and the background color painted into it.
    view.wantsLayer = initialWantsLayer

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
    guard let bitmap = try? makeBitmap(size: size, displayScale: displayScale) else {
      // Unreachable in practice: `validateRenderable(size:displayScale:)` pre-flights the exact
      // same allocation at request-generation time and throws a recoverable `SnapshotError`
      // before any crashing render is produced. Returning an empty image here is a non-crashing
      // backstop rather than the former `fatalError`, which terminated the whole test process.
      return NSImage(size: size)
    }

    bitmap.size = size
    view.cacheDisplay(in: view.bounds, to: bitmap)

    let image = NSImage(size: size)
    image.addRepresentation(bitmap)

    return image
  }

  /// Pre-flights the render's bitmap allocation for a request's size and scale, throwing a
  /// recoverable ``SnapshotError`` when the pixel grid is unrenderable — either because
  /// `size × displayScale` overflows `Int` or because `NSBitmapImageRep` cannot allocate a
  /// backing that large. Called from request generation (a `throws` context) so a huge-but-finite
  /// `.fixed` size — which passes positivity/finiteness validation but has no upper bound — is
  /// recorded as a test issue instead of crashing the entire test process at render time.
  static func validateRenderable(size: CGSize, displayScale: Double) throws {
    _ = try makeBitmap(size: size, displayScale: displayScale)
  }

  /// Allocates the sRGB-tagged bitmap the render draws into, or throws ``SnapshotError`` when the
  /// pixel dimensions are non-positive, overflow `Int`, or exceed what `NSBitmapImageRep` can
  /// allocate.
  ///
  /// The pixel grid is `size × displayScale`, tagged sRGB before drawing so colors land in a
  /// fixed, machine-independent color space (`bitmapImageRepForCachingDisplay` would otherwise
  /// inherit the recording screen's display profile).
  /// The largest bitmap the renderer will allocate, in bytes. Real UI snapshots stay far below
  /// this (a full 6K display at 3× is well under 1 GiB of RGBA8), so 2 GiB comfortably admits
  /// every legitimate request while rejecting pathological ones — a `.fixed(50000)` square at 2×
  /// asks for ~40 GB, which would OOM-crash the process. The cap is enforced explicitly rather
  /// than by trusting `NSBitmapImageRep` to return `nil`, whose out-of-range threshold varies by
  /// OS version (on macOS 27 it lazily accepts a 100000×100000 rep and only crashes when drawn).
  private static let maximumBitmapByteCount = 2.0 * 1024 * 1024 * 1024

  private static func makeBitmap(size: CGSize, displayScale: Double) throws -> NSBitmapImageRep {
    let pixelsWideValue = (size.width * displayScale).rounded()
    let pixelsHighValue = (size.height * displayScale).rounded()
    let bytesPerPixel = 4.0

    guard
      pixelsWideValue >= 1, pixelsHighValue >= 1,
      // Guard the `Int` conversion: `Int(_:)` on a `Double` at or beyond `Int.max` traps.
      pixelsWideValue < Double(Int.max), pixelsHighValue < Double(Int.max),
      pixelsWideValue * pixelsHighValue * bytesPerPixel <= maximumBitmapByteCount,
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pixelsWideValue),
        pixelsHigh: Int(pixelsHighValue),
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
      throw SnapshotError(
        message: """
          Snapshot size \(size) at scale \(displayScale) is too large to render \
          (\(pixelsWideValue) × \(pixelsHighValue) pixels). Reduce the requested size or scale.
          """
      )
    }

    return bitmap
  }
}
#endif
