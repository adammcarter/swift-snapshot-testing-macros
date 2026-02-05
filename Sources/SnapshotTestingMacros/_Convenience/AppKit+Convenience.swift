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
    set { layer?.backgroundColor = newValue?.cgColor }
  }
}
#endif
