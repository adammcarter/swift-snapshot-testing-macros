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
#endif
