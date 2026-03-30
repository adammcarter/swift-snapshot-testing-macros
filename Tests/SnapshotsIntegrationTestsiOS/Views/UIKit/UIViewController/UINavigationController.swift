#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import SnapshotSupport
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(devices: .iPhoneX),
    .theme(.light)
  )
  struct _UINavigationController {  // swiftlint:disable:this type_name

    @SnapshotTest
    func uiNavigationController() -> UIViewController {
      with(UINavigationController(rootViewController: makeController(labeled: #function))) {
        $0.view.backgroundColor = .secondarySystemBackground
      }
    }
  }
}
#endif
