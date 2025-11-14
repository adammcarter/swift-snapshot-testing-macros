#if canImport(UIKit)
import SnapshotSupport
import UIKit

@MainActor
func makeController(labeled string: String? = nil) -> UIViewController {
  with(UIViewController()) {
    $0.view.backgroundColor = .systemBackground

    if let string {
      $0.view.addLabel(string: string)
    }
  }
}
#endif
