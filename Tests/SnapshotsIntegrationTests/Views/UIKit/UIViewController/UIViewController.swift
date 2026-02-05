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
  struct _UIViewController {  // swiftlint:disable:this type_name

    @SnapshotTest
    func uiViewController() -> UIViewController {
      makeController(labeled: #function)
    }

    @SnapshotTest(
      configurations: [
        .init(name: "zero inset", value: 0.0),
        .init(name: "ten inset", value: 10.0),
        .init(name: "fifty inset", value: 50.0),
      ]
    )
    func uiViewControllerWithSafeArea(inset: Double) -> UIViewController {
      with(makeController()) { viewController in
        viewController.additionalSafeAreaInsets = .init(top: inset, left: inset, bottom: inset, right: inset)

        let safeAreaView = with(UIView()) {
          $0.backgroundColor = .secondarySystemBackground
        }

        viewController.view.addSubview(safeAreaView)

        safeAreaView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          safeAreaView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
          safeAreaView.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor),
          safeAreaView.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor),
          safeAreaView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
        ])

        safeAreaView.addLabel(string: "\(#function): \(inset.formatted())")
      }
    }
  }

  @MainActor
  @Suite
  @SnapshotSuite(
    .theme(.light)
  )
  struct _UIViewController_preferredContentSize {  // swiftlint:disable:this type_name

    @SnapshotTest(
      .sizes(.minimum)
    )
    func preferredContentSize() -> UIViewController {
      makePreferredContentSizeController()
    }

    @SnapshotTest(
      .sizes(width: .minimum, height: 300)
    )
    func preferredContentSize_minimumWidth() -> UIViewController {
      makePreferredContentSizeController()
    }

    @SnapshotTest(
      .sizes(width: 300, height: .minimum)
    )
    func preferredContentSize_minimumHeight() -> UIViewController {
      makePreferredContentSizeController()
    }

    @SnapshotTest(
      .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
    )
    func preferredContent_iPhoneX_widthButMinimumHeight() -> UIViewController {
      makePreferredContentSizeController()
    }

    private func makePreferredContentSizeController(labeled label: String = #function) -> UIViewController {
      with(makeController(labeled: label)) {
        $0.preferredContentSize = .init(width: 400, height: 200)
      }
    }
  }
}
#endif
