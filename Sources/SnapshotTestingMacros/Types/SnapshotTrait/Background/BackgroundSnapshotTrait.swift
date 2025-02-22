#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct BackgroundSnapshotTrait: SnapshotTrait {
  #if canImport(UIKit)
  public typealias BackgroundColor = UIColor
  #elseif canImport(AppKit)
  public typealias BackgroundColor = NSColor
  #endif

  let backgroundColor: BackgroundColor

  public var debugDescription: String {
    "backgroundColor: \(backgroundColor)"
  }

  init(backgroundColor: BackgroundColor) {
    self.backgroundColor = backgroundColor
  }
}
