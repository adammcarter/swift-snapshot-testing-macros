#if canImport(SwiftUI)
import SnapshotSupport
import SwiftUI

extension SnapshotViewGenerator {
  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> any SwiftUI.View,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      displayName: displayName,
      configuration: configuration,
      makeValue: {
        try await makeSnapshotView(from: makeValue($0))
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

@MainActor
private func makeSnapshotView<V: SwiftUI.View>(from view: V) async throws -> SnapshotViewController {
  let controller = SnapshotHostingController(rootView: view)
  controller.view.backgroundColor = nil

  if #available(iOS 16.0, *) {
    controller.sizingOptions = [.intrinsicContentSize, .preferredContentSize]
  }

  return controller
}
#endif
