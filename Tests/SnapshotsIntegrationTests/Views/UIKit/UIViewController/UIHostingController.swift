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
  struct _UIHostingController {  // swiftlint:disable:this type_name

    #if canImport(SwiftUI)
    @SnapshotTest
    func uiHostingController() -> UIViewController {
      UIHostingController(
        rootView: VStack {
          Text(#function)
        }
      )
    }
    #endif
  }
}
#endif
