import Foundation

public enum LegacyPlatform {
  case swiftUI
  case uiKitOrAppKit
  case unsupported
}

public enum PlatformClassifier {
  public static func classify(returnType: String) -> LegacyPlatform {
    switch returnType.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "some View":
      return .swiftUI
    case "UIView", "UIViewController", "NSView", "NSViewController":
      return .uiKitOrAppKit
    default:
      return .unsupported
    }
  }
}
