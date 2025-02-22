import Foundation

extension Constants {
  enum Configuration {
    static let supportedReturnTypes: Set<String> = {
      [
        "some View",
        "NSViewController",
        "NSView",
        "UIViewController",
        "UIView",
      ]
    }()
  }
}
