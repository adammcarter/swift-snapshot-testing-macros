#if canImport(AppKit)
import AppKit

extension NSDirectionalEdgeInsets {
  static var zero: NSDirectionalEdgeInsets { .init(top: 0, leading: 0, bottom: 0, trailing: 0) }
}

extension NSDirectionalEdgeInsets: @retroactive Equatable {
  public static func == (lhs: NSDirectionalEdgeInsets, rhs: NSDirectionalEdgeInsets) -> Bool {
    [lhs.top, lhs.leading, lhs.bottom, lhs.trailing] == [rhs.top, rhs.leading, rhs.bottom, rhs.trailing]
  }
}

extension NSView {
  var backgroundColor: NSColor? {
    get { layer?.backgroundColor.flatMap { .init(cgColor: $0) } }
    set {
      if newValue != nil {
        // A backing layer only exists once the view opts into layer-backing; without this the
        // write below would silently no-op through the `nil` layer (unlike UIKit, where every
        // view is layer-backed).
        wantsLayer = true
      }

      layer?.backgroundColor = newValue?.cgColor
    }
  }
}
#endif
