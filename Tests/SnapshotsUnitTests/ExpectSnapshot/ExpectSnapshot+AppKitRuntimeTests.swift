#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

struct ExpectSnapshotAppKitRuntimeTests {
  @Test
  func nsView() {
    #expectSnapshot(makeLabel("AppKit direct value"))
  }

  @Test
  func nsViewController() {
    #expectSnapshot(makeController(labeled: "AppKit controller direct value"))
  }

  /// Mirrors the body shape the migration rewriter emits for legacy
  /// `configurationValues:` tests on AppKit/UIKit platforms; artifacts land in the legacy
  /// layout `<display>/<case>_<display>_<size>_<theme>`.
  ///
  /// Plain views keep the recursive-description artifacts free of private AppKit class
  /// names, so the recorded references stay stable across OS versions.
  @MainActor
  @Test(.strategy(.recursiveDescription), .theme(.light), arguments: [1, 2])
  func migratedParameterizedController(value: Int) {
    let snapshotConfiguration = SnapshotConfiguration(name: "\(value)", value: value)
    let snapshotValue: NSViewController = makePlainController(width: 200, height: 100)
    #expectSnapshot(snapshotConfiguration, named: "Migrated parameterized controller") { _ in snapshotValue }
  }

  /// Mirrors the body shape the migration rewriter emits for legacy `configurations:`
  /// tests on AppKit/UIKit platforms.
  @MainActor
  @Test(
    .strategy(.recursiveDescription),
    .theme(.light),
    arguments: [SnapshotConfiguration(name: "compact", value: 120.0)]
  )
  func migratedParameterizedView(configuration: SnapshotConfiguration<Double>) {
    let snapshotConfiguration = configuration
    let width = configuration.value
    let snapshotValue: NSView = makePlainView(width: width, height: 80)
    #expectSnapshot(snapshotConfiguration, named: "Migrated parameterized view") { _ in snapshotValue }
  }
}

@MainActor
private func makeLabel(_ string: String) -> NSTextField {
  let label = NSTextField(labelWithString: string)
  label.sizeToFit()
  return label
}

@MainActor
private func makeController(labeled string: String) -> NSViewController {
  let controller = NSViewController()
  controller.view = makeLabel(string)
  return controller
}

@MainActor
private func makePlainView(width: Double, height: Double) -> NSView {
  let view = NSView(frame: .init(x: 0, y: 0, width: width, height: height))
  view.widthAnchor.constraint(equalToConstant: width).isActive = true
  view.heightAnchor.constraint(equalToConstant: height).isActive = true
  return view
}

@MainActor
private func makePlainController(width: Double, height: Double) -> NSViewController {
  let controller = NSViewController()
  controller.view = makePlainView(width: width, height: height)
  return controller
}
#endif
