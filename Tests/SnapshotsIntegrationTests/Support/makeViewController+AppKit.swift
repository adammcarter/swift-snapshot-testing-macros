#if canImport(AppKit)
import AppKit
import SnapshotSupport

@MainActor
func makeController(labeled string: String? = nil) -> NSViewController {
  with(NSViewController()) {
    $0.view = NSView()
    $0.view.wantsLayer = true
    $0.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

    if let string {
      $0.view.addLabel(string: string)
    }
  }
}
#endif
