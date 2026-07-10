import Foundation
import SnapshotSupport

/// Hosts a caller-supplied platform view through the standard controller lifecycle.
///
/// Assigning `controller.view` directly marks the view as loaded without ever running the
/// documented `loadView()`/`viewDidLoad()` sequence (on both UIKit and AppKit). This container
/// vends the injected view from `loadView()` instead, so lifecycle hooks keep their contract
/// and any future setup added to controller lifecycle overrides actually runs.
class SnapshotInjectedViewController: SnapshotViewController {
  private let injectedView: SnapshotView

  init(view: SnapshotView) {
    self.injectedView = view
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("SnapshotInjectedViewController does not support init(coder:)")
  }

  override func loadView() {
    view = injectedView
  }
}

extension SnapshotViewGenerator {
  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotView,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      displayName: displayName,
      configuration: configuration,
      makeValue: {
        SnapshotInjectedViewController(view: try makeValue($0))
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  public init(
    displayName: String,
    configuration: SnapshotConfiguration<ConfigurationValue>,
    makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotView,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      displayName: displayName,
      configuration: configuration,
      makeValue: {
        SnapshotInjectedViewController(view: try await makeValue($0))
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}
