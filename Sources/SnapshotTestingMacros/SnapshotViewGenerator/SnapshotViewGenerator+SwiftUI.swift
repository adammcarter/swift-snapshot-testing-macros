#if canImport(SwiftUI)
import SnapshotSupport
import SwiftUI

extension SnapshotViewGenerator {
  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> any SwiftUI.View,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      displayName: displayName,
      configuration: configuration,
      makeValue: {
        try makeSnapshotView(from: makeValue($0))
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

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
      makeValue: { try makeSnapshotView(from: await makeValue($0)) },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

@MainActor
private func makeSnapshotView<V: SwiftUI.View>(from view: V) throws -> SnapshotViewController {
  let controller = SnapshotHostingController(rootView: view)
  controller.view.backgroundColor = nil

  // `sizingOptions` exists from iOS 16 (UIHostingController) and macOS 13
  // (NSHostingController); name both so the check states the real dependency
  // instead of relying on the `*` wildcard to admit every macOS version.
  if #available(iOS 16.0, macOS 13.0, *) {
    controller.sizingOptions = [.intrinsicContentSize, .preferredContentSize]
  }

  return controller
}
#endif
