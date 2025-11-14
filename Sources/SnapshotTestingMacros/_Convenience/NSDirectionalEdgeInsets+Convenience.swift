#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension NSDirectionalEdgeInsets {
  init(all value: CGFloat) {
    self.init(top: value, leading: value, bottom: value, trailing: value)
  }
}
