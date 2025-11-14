#if canImport(SwiftUI)
import SwiftUI
#endif

@MainActor
extension SnapshotTrait where Self == BackgroundColorSnapshotTrait {
  #if canImport(UIKit)
  public static func backgroundColor(
    uiColor: UIColor
  ) -> Self {
    Self(backgroundColor: uiColor)
  }
  #elseif canImport(AppKit)
  public static func backgroundColor(
    nsColor: NSColor
  ) -> Self {
    Self(backgroundColor: nsColor)
  }
  #endif

  #if canImport(SwiftUI)
  public static func backgroundColor(
    _ color: Color
  ) -> Self {
    Self(backgroundColor: .init(color))
  }
  #endif
}
