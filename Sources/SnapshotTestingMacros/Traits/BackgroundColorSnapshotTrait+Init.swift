#if canImport(SwiftUI)
import SwiftUI
#endif

@MainActor
extension SnapshotTrait where Self == BackgroundColorSnapshotTrait {
  #if canImport(UIKit)
  /// Sets the background color for the snapshot using a `UIColor`.
  ///
  /// - Parameter uiColor: The background color.
  /// - Returns: A trait that applies the background color.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.backgroundColor(uiColor: .red))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func backgroundColor(
    uiColor: UIColor
  ) -> Self {
    Self(backgroundColor: uiColor)
  }
  #elseif canImport(AppKit)
  /// Sets the background color for the snapshot using an `NSColor`.
  ///
  /// - Parameter nsColor: The background color.
  /// - Returns: A trait that applies the background color.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.backgroundColor(nsColor: .red))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func backgroundColor(
    nsColor: NSColor
  ) -> Self {
    Self(backgroundColor: nsColor)
  }
  #endif

  #if canImport(SwiftUI)
  /// Sets the background color for the snapshot using a SwiftUI `Color`.
  ///
  /// - Parameter color: The background color.
  /// - Returns: A trait that applies the background color.
  ///
  /// Example:
  /// ```swift
  /// @Suite
  /// struct MySnapshotSuite {
  ///
  ///   @Test(.backgroundColor(.blue))
  ///   func myView() {
  ///     #expectSnapshot(MyView())
  ///   }
  /// }
  /// ```
  public static func backgroundColor(
    _ color: Color
  ) -> Self {
    Self(backgroundColor: .init(color))
  }
  #endif
}
