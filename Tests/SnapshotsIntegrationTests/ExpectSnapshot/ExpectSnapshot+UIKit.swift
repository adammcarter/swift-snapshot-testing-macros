#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

struct ExpectSnapshotUIKitTests {
  @Test
  func uiView() {
    #expectSnapshot(makeLabel("UIKit direct value"))
  }

  @Test
  func uiViewController() {
    #expectSnapshot(makeController(labeled: "UIKit controller direct value"))
  }
}
#endif
