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
    .theme(.dark)
  )
  struct _UITabBarController {  // swiftlint:disable:this type_name

    @SnapshotTest
    func uiTabController() -> UIViewController {
      with(UITabBarController()) {
        $0.setViewControllers(
          [
            with(makeController(labeled: "a")) {
              $0.tabBarItem = .init(title: "a", image: .init(systemName: "star"), tag: 0)
            },
            with(makeController(labeled: "b")) {
              $0.tabBarItem = .init(title: "b", image: .init(systemName: "triangle"), tag: 1)
            },
          ],
          animated: false
        )
      }
    }

    @SnapshotTest(
      .padding(20)
    )
    func uiTabControllerPadding() -> UIViewController {
      uiTabController()
    }

    @SnapshotTest(
      .backgroundColor(.red)
    )
    func uiTabControllerBackground() -> UIViewController {
      uiTabController()
    }

    @SnapshotTest(
      .backgroundColor(.red),
      .padding(20)
    )
    func uiTabControllerBackgroundAndPadding() -> UIViewController {
      uiTabController()
    }

    @SnapshotTest
    @available(iOS 18.0, *)
    func uiTabController_ios18() -> UIViewController {
      UITabBarController(tabs: [
        .init(title: "a", image: .init(systemName: "star"), identifier: "a", viewControllerProvider: { _ in makeController(labeled: "a") }),
        .init(title: "b", image: .init(systemName: "triangle"), identifier: "b", viewControllerProvider: { _ in makeController(labeled: "b") }),
      ])
    }
  }
}
#endif
