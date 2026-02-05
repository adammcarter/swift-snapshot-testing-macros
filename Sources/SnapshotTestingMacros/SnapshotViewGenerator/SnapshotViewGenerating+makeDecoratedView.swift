import Foundation
import SnapshotSupport

extension SnapshotViewGenerating {

  func makeDecoratedView() async throws -> SnapshotViewController {
    let payloadController = try await makeViewController(configuration.value)

    return decorate(payloadController)
  }

  private func decorate(_ viewController: SnapshotViewController) -> SnapshotViewController {
    guard let configuration = __SnapshotViewDecoratorConfiguration.value else {
      return viewController
    }

    return with(viewController.wrappingInContainerViewController(insets: configuration.padding ?? .zero)) {
      $0.view.backgroundColor = configuration.backgroundColor
    }
  }
}
