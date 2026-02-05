#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension SnapshotViewController {
  func wrappingInContainerViewController(
    insets: NSDirectionalEdgeInsets = .zero
  ) -> SnapshotViewController {
    let parentViewController = SnapshotViewController()
    parentViewController.addChild(self)

    view.translatesAutoresizingMaskIntoConstraints = false

    parentViewController.view.addSubview(view)

    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor, constant: insets.leading),
      view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor, constant: -insets.trailing),
      view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor, constant: insets.top),
      view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor, constant: -insets.bottom),
    ])

    #if canImport(UIKit)
    didMove(toParent: parentViewController)
    #endif

    return parentViewController
  }
}

extension SnapshotViewController {
  func embedChild(
    _ childController: SnapshotViewController,
    insets: NSDirectionalEdgeInsets = .zero
  ) {
    addChild(childController)

    childController.view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(childController.view)

    NSLayoutConstraint.activate([
      childController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
      childController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
      childController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
      childController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
    ])

    #if canImport(UIKit)
    childController.didMove(toParent: self)
    #endif
  }
}
